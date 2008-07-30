class Backend::TakeBackController < Backend::BackendController

  before_filter :pre_load

  def index
                                              
    if params[:search]
      params[:search] = "*#{params[:search]}*" # search with partial string
      @contracts = current_inventory_pool.contracts.signed_contracts.find_by_contents(params[:search])

      # OPTIMIZE named_scope intersection?
      @visits = current_inventory_pool.take_back_visits.select {|v| v.contract_lines.any? {|l| @contracts.include?(l.contract) } }
      
    elsif params[:user_id]
      # OPTIMIZE named_scope intersection?
      @visits = current_inventory_pool.take_back_visits.select {|v| v.user == @user}
      
    elsif params[:remind] #temp#
      @visits = current_inventory_pool.remind_visits
      
    else
      @visits = current_inventory_pool.take_back_visits
      
    end
    
    render :partial => 'visits' if request.post?
  end

  # get current contracts for a given user
  def show
    @contract_lines = @user.get_signed_contract_lines
    @contract_lines.sort! {|a,b| a.end_date <=> b.end_date}
  end

  # Close definitely the contract
  def close_contract
    if request.post?
      #temp# @lines = @user.get_signed_contract_lines.find(params[:lines].split(','))
      @lines = ContractLine.find(params[:lines]) #if params[:lines] # TODO scope current_inventory_pool
      @contracts = @lines.collect(&:contract).uniq #if @lines

      # set the return dates to the given contract_lines
      @lines.each { |l| l.update_attribute :returned_date, Date.today }
  
      @contracts.each do |c|
        c.close if c.lines.all? { |l| !l.returned_date.nil? }
      end
      
      redirect_to :action => 'print_contract', :lines => @lines
    else
      @lines = ContractLine.find(params[:lines].split(',')) if params[:lines] # TODO scope current_inventory_pool
      render :layout => $modal_layout_path
    end    
  end

  # Creating the contract to print
  def print_contract
    respond_to do |format|
      format.html { @lines = ContractLine.find(params[:lines]) #if params[:lines] # TODO scope current_inventory_pool
                    @contracts = @lines.collect(&:contract).uniq #if @lines
                    render :layout => $modal_layout_path }
      format.pdf { send_data(render(:layout => false, :template => "backend/hand_over/print_contract"), :filename => "contract_#{@contract.id}.pdf") }
    end
  end
  
  
  # given an inventory_code, searches for the matching contract_line
  def assign_inventory_code
    if request.post?
      item = current_inventory_pool.items.find(:first, :conditions => { :inventory_code => params[:code] })
      unless item.nil?
        contract_lines = @user.get_signed_contract_lines
    
        contract_lines.sort! {|a,b| a.end_date <=> b.end_date} # TODO select first to take back
        @contract_line = contract_lines.detect {|cl| cl.item_id == item.id }
        @contract_line.update_attribute :start_date, Date.today

        @contract = @contract_line.contract # TODO optimize errors report
      end
      render :action => 'change_line'
    end
  end

  def timeline
    @timeline_xml = @user.timeline
    render :text => "", :layout => 'backend/' + $theme + '/modal_timeline'
  end

  private
  
  def pre_load
    @user = User.find(params[:user_id]) if params[:user_id] # TODO scope current_inventory_pool    
    @contract = Contract.find(params[:contract_id]) if params[:contract_id]
  end
    
end
