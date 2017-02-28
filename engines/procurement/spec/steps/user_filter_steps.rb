require_relative 'shared/personas_steps'

steps_for :user_filter do
  include PersonasSteps

  step 'I am also a requester' do
    FactoryGirl.create(:procurement_access, :requester,
                       user: @current_user)
  end

  step 'I have a user filter set' do
    FactoryGirl.create(:procurement_user_filter, user: @current_user)
  end

  step 'my requester access is deleted' do
    Procurement::Access.find_by!(user: @current_user, is_admin: nil)
      .destroy
  end

  step 'my user filter still exists' do
    expect(Procurement::UserFilter.find_by_user_id(@current_user.id)).to be
  end

  step 'my admin access is deleted' do
    Procurement::Access.find_by!(user: @current_user, is_admin: true)
      .destroy
  end

  step 'my user filter is deleted too' do
    expect(Procurement::UserFilter.find_by_user_id(@current_user.id)).not_to be
  end

  step 'there is a user with filter' do
    @user = FactoryGirl.create(:user)
  end

  step 'the user is deleted' do
    @user.destroy
  end

  step 'the filter is deleted too' do
    expect(Procurement::UserFilter.find_by_user_id(@user.id)).not_to be
  end
end
