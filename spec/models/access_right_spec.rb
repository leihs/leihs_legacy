require 'rails_helper'

describe AccessRight do

  before :each do
    PgTasks.truncate_tables()
    FactoryGirl.create(:setting) unless Setting.first
  end

  context 'a user and a pool' do

    before :example do
      @user = FactoryGirl.create :user
      @inventory_pool = FactoryGirl.create :inventory_pool
    end

    it 'an AccessRight can be created' do
      expect(AccessRight.create user: @user,
             inventory_pool: @inventory_pool,
             role: 'customer').to be
    end

    it 'an AccessRight can be created with specifying its id and found by the id' do
      id = SecureRandom.uuid
      AccessRight.create id: id,
        user: @user,
        inventory_pool: @inventory_pool,
        role: 'customer'
      expect(AccessRight.find_by id: id).to be
    end

    context 'a created access_right' do

      before :example do
        @access_right = AccessRight.create user: @user,
          inventory_pool: @inventory_pool,
          role: 'customer'
      end

      it 'can be found by id' do
        expect(AccessRight.find_by id: @access_right.id).to be
      end

      it 'its role can be updated' do
        @access_right.update_attributes role: 'inventory_manager'
        expect(AccessRight.find_by(id: @access_right.id).role.to_s).to be== 'inventory_manager'
      end

      it 'can be deleted' do
        @access_right.delete
        expect(AccessRight.find_by(id: @access_right.id)).not_to be
      end

      it 'can be destroyed' do
        @access_right.destroy!
        expect(AccessRight.find_by(id: @access_right.id)).not_to be
      end


      context 'further pools, and users with direct_access_rights' do

        before :each do
          @users = 10.times.map { FactoryGirl.create :user }
          @pools = 3.times.map { FactoryGirl.create :inventory_pool}
          @direct_access_rights = 10.times.map {|i|
            FactoryGirl.create :direct_access_right, user: @users[i], inventory_pool: @pools.sample}
        end

        it 'access_rights reflect direct_access_rights properly' do

          @direct_access_rights.each do |dar|
            ar = AccessRight.find_by_id dar.id
            expect(ar.user_id).to be== dar.user_id
            expect(ar.inventory_pool_id).to be== dar.inventory_pool_id
            expect(ar.role.to_s).to be== dar.role
          end
        end

        context 'creating a further access_right' do
          before :each do
            AccessRight.create user: @user, inventory_pool: @pools.first, role: :customer
          end
          it 'does not touch the existing access_rights and they still reflect direct_access_rights properly' do
            @direct_access_rights.each do |dar|
              ar = AccessRight.find_by_id dar.id
              expect(ar.user_id).to be== dar.user_id
              expect(ar.inventory_pool_id).to be== dar.inventory_pool_id
              expect(ar.role.to_s).to be== dar.role
            end
          end
        end

        context 'deleting some other access_right' do
          before :each do
            @access_right.destroy
          end
          it 'does not touch the existing access_rights and they still reflect direct_access_rights properly' do
            @direct_access_rights.each do |dar|
              ar = AccessRight.find_by_id dar.id
              expect(ar.user_id).to be== dar.user_id
              expect(ar.inventory_pool_id).to be== dar.inventory_pool_id
              expect(ar.role.to_s).to be== dar.role
            end
          end
        end

        context 'updating some other access_right' do
          before :each do
            @access_right.update_attributes! role: :group_manager
          end
          it 'does really update the access_right in the database' do
            expect( AccessRight.find_by(user_id: @user.id, inventory_pool_id: @inventory_pool.id).role).to be== :group_manager
          end
          it 'does not touch the existing access_rights and they still reflect direct_access_rights properly' do
            @direct_access_rights.each do |dar|
              ar = AccessRight.find_by_id dar.id
              expect(ar.user_id).to be== dar.user_id
              expect(ar.inventory_pool_id).to be== dar.inventory_pool_id
              expect(ar.role.to_s).to be== dar.role
            end
          end
        end

      end
    end
  end
end
