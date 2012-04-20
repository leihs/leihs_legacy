# == Schema Information
#
# Table name: orders
#
#  id                :integer(4)      not null, primary key
#  user_id           :integer(4)
#  inventory_pool_id :integer(4)
#  status_const      :integer(4)      default(1)
#  purpose           :text
#  created_at        :datetime
#  updated_at        :datetime
#  delta             :boolean(1)      default(TRUE)
#

# An Order is a #Document containing #OrderLine s.
# It's created by a customer, that wants to borrow
# some stuff. In the workflow of the lending process
# once the Order gets to the #InventoryPool manager
# it is copied over into a #Contract.
#
# An Order can not contain #Options - contrary to a
# #Contract, that can have them.
#
# The page "Flow" inside the models.graffle document shows the
# various steps though which a #Document goes from #Order to
# finally closed Contract.
#
class Order < Document

  attr_protected :created_at

  belongs_to :inventory_pool # common for sibling classes
  belongs_to :user
  has_many :order_lines, :dependent => :destroy, :order => 'start_date ASC, end_date ASC, created_at ASC'
  has_many :models, :through => :order_lines, :uniq => true

  validate :validates_order_lines

  acts_as_commentable

  UNSUBMITTED = 1
  SUBMITTED = 2
  APPROVED = 3
  REJECTED = 4

  STATUS = {_("Unsubmitted") => UNSUBMITTED, _("Submitted") => SUBMITTED, _("Approved") => APPROVED, _("Rejected") => REJECTED }

  def status_string
    n = STATUS.index(status_const)
    n.nil? ? status_const : n
  end

  # alias
  def lines( reload = false )
    order_lines( reload )
  end

#########################################################################
  
  default_scope order('created_at ASC')
  
  scope :unsubmitted, where(:status_const => Order::UNSUBMITTED)
  scope :submitted, where(:status_const => Order::SUBMITTED) # OPTIMIZE N+1 select problem
  scope :approved, where(:status_const => Order::APPROVED) # TODO 0501 remove
  scope :rejected, where(:status_const => Order::REJECTED)

  scope :by_inventory_pool,  lambda { |inventory_pool| where(:inventory_pool_id => inventory_pool) }

#########################################################################
  
  def self.search2(query)
    return scoped unless query

    sql = select("DISTINCT orders.*").joins(:user, :models)

    w = query.split.map do |x|
      s = []
      s << "CONCAT_WS(' ', users.login, users.firstname, users.lastname, users.badge_id) LIKE '%#{x}%'"
      s << "models.name LIKE '%#{x}%'"
      "(%s)" % s.join(' OR ')
    end.join(' AND ')
    sql.where(w)
  end

  def self.filter2(options)
    sql = scoped
    options.each_pair do |k,v|
      case k
        when :inventory_pool_id
          sql = sql.where(k => v)
      end
    end
    sql
  end

#########################################################################

  def is_approved?
    self.status_const == Order::APPROVED
  end

  def approvable?
    if is_approved?
      errors.add(:base, _("This order has already been approved."))
      false
    elsif lines.empty?
      errors.add(:base, _("This order is not approvable because doesn't have any models."))
      false
    elsif lines.all? {|l| l.available? }
      true
    else
      errors.add(:base, _("This order is not approvable because some reserved models are not available."))
      false
    end
  end
  alias :is_approvable :approvable?


  # TODO 13** forward purpose
  # approves order then generates a new contract and item_lines for each item
  def approve(comment, send_mail = true, current_user = nil, force = false)
    if approvable? || force
      self.status_const = Order::APPROVED
      save

      contract = user.get_current_contract(self.inventory_pool)
      order_lines.each do |ol|
        ol.quantity.times do
          contract.item_lines.create( :model => ol.model,
                                      :quantity => 1,
                                      :start_date => ol.start_date,
                                      :end_date => ol.end_date)
        end
      end   
      contract.save

      begin
        Notification.order_approved(self, comment, send_mail, current_user)
      rescue Exception => exception
        # archive problem in the log, so the admin/developper
        # can look up what happened
        logger.error "#{exception}\n    #{exception.backtrace.join("\n    ")}"
        self.errors.add(:base,
          _("The following error happened while sending a notification email to %{email}:\n") % { :user => user.email } +
          "#{exception}.\n" +
          _("That means that the user probably did not get the approval mail and you need to contact him/her in a different way."))
      end

      return true
    else
      return false
    end
  end

  # submits order
  def submit(purpose = nil)
    self.purpose = purpose if purpose
    save

    if approvable?
      self.status_const = Order::SUBMITTED
      split_and_assign_to_inventory_pool

      Notification.order_submitted(self, purpose, false)
      Notification.order_received(self, purpose, true)
      return true
    else
      return false
    end
  end

  def add_line(quantity, model, user_id, start_date = nil, end_date = nil, inventory_pool = nil)
    line = lines.where(:model_id => model, :start_date => start_date, :end_date => end_date).first
    if line
      line.quantity += quantity
      if line.save
        log_change( _("Incremented quantity from %i to %i for %s") % [line.quantity-quantity, line.quantity, model.name], user_id )        
      end
    else
      line = super
    end
    line
  end

  # keep the user required quantity, force positive quantity 
  def update_line(order_line_id, required_quantity, user_id)
    order_line = order_lines.find(order_line_id)
    original_quantity = order_line.quantity
        
    max_available = order_line.maximum_available_quantity

    order_line.quantity = [required_quantity, 0].max
    order_line.save

    change = _("Changed quantity for %{model} from %{from} to %{to}") % { :model => order_line.model.name, :from => original_quantity, :to => order_line.quantity }
    if required_quantity > max_available
      @flash_notice = _("Maximum number of items available at that time is %{max}") % {:max => max_available}
      change += " " + _("(maximum available: %{max})") % {:max => max_available}
    end
    log_change(change, user_id)
    [order_line, change]
  end
  
  def change_purpose(new_purpose, user_id)
    change = _("Purpose changed '%{from}' for '%{to}'") % { :from => self.purpose, :to => new_purpose}
    self.purpose = new_purpose
    log_change(change, user_id)
    save
  end  

  # OPTIMIZE scope new_user_id by current_inventory_pool
  def swap_user(new_user_id, admin_user_id)
    user = User.find(new_user_id)
    if (user.id != self.user_id.to_i)
      change = _("User swapped %{from} for %{to}") % { :from => self.user.login, :to => user.login}
      self.user = user
      log_change(change, admin_user_id)
      save
    end
  end  
  
  def deletable_by_user?
    status_const == Order::SUBMITTED 
  end

  def waiting_for_hand_over
    if is_approved? and lines.maximum(:start_date) >= Date.today
      contract = user.current_contract(inventory_pool)
      return true if contract and not contract.lines.empty?
    end
    return false
  end
  
  def min_date
    unless order_lines.blank?
      order_lines.min {|x| x.start_date}[:start_date]
    else
      nil
    end
  end
  
  def max_date
    unless order_lines.blank?
      order_lines.max {|x| x.end_date }[:end_date]
    else
      nil
    end
  end
  
  ############################################
  
  # example: ip.orders.submitted.as_json(:with => {:user => {}, :lines => {:with => {:availability => {:inventory_pool => ip}},}})
  def as_json(options = {})
    options ||= {} # NOTE workaround, because options is nil, is this a BUG ??
    options.delete_if {|k,v| v.nil? }
    
    default_options = {:only => [:id, :inventory_pool_id, :purpose, :status_const, :created_at, :updated_at]}
    more_json = {}
    
    if (with = options[:with])
      if with[:user]
        user_default_options = {:include => {:user => {:only => [:firstname, :lastname, :id, :phone, :email],
                                                       :methods => [:image_url] }}}
        default_options.deep_merge!(user_default_options.deep_merge(with[:user]))
      end

      if with[:lines]
        more_json['lines'] = lines.as_json(with[:lines])
      end
    end
    
    json = super(default_options.deep_merge(options))
    json['type'] = :order # needed for templating (type identifier)
    
    json.merge(more_json)
  end
  
  ############################################

  private
  
  # TODO assign based on the order_lines' inventory_pools
  def split_and_assign_to_inventory_pool
      inventory_pools = lines.flat_map(&:inventory_pool).uniq
      inventory_pools.each do |ip|
        if ip == inventory_pools.first
          self.inventory_pool = ip
          next          
        end
        to_split_lines = lines.select {|l| l.inventory_pool == ip }
        attrs = self.attributes.reject {|k,v| [:id, :created_at, :updated_at].include? k.to_sym }
        o = Order.new(attrs)
        o.inventory_pool = ip
        to_split_lines.each {|l| o.lines << l }
        o.save        
      end
      save
  end

  def validates_order_lines
    # TODO ?? model.inventory_pools.include?(order.inventory_pool)
    errors.add(:base, _("Invalid order_lines")) if lines.any? {|l| !l.valid? }
  end
  
end

