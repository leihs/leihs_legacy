Feature: Implement new Group feature

        Background: Provide a minimal lending environment
                Given the settings are existing
                  And inventory pool 'AVZ'
                  And a lending_manager 'lendingmanager' for inventory pool 'AVZ'
                  And I am logged in as 'lendingmanager' with password 'foobar'

        Scenario: Have multiple groups, lend and return an item
                Given a customer "mongobill"

                When I register a new model 'Olympus PEN E-P2'
                Then that model should not be available to anybody

                When I add 2 items of that model
                Then 2 items of that model should be available to everybody

                When I add 1 item of that model
                Then 3 items of that model should be available to everybody

                When I add a group called "CAST"

                Then 3 items of that model should be available to everybody
                 And that model should not be available in any group

                When I assign one item to group "CAST"
                Then 2 items of that model should be available to everybody
                 And one item of that model should be available in group 'CAST'

                Given a customer "tomas" that belongs to group "CAST"
                When I lend one item of that model to "tomas"
                Then 2 items of that model should be available to everybody

                When I add a group called "Video"
                 And I assign 2 items to group "Video"
                Then 0 items of that model should be available to "tomas"


        Scenario: Quantity entitled to a specific group has always precedence over general group
                Given a model 'Olympus PEN E-P2' exists
                  And a customer "mbill"
                  And a group 'CAST'
                  And a customer "tomas" that belongs to group "CAST"

                When I add 1 item of that model
                 And I assign one item to group "CAST"
                Then 0 items of that model should be available to "mbill"

                When I add 1 item of that model
                 And I lend one item of that model to "mbill"
                 And I lend one item of that model to "tomas"
                Then 0 items of that model should be available to "mbill"

                When "tomas" returns the item
                Then 0 items of that model should be available to "mbill"
