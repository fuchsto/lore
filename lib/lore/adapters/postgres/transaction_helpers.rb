
module Lore
module Postgres

  # Extension module for Connection adapters with 
  # transaction support. 
  #
  # You will never have to use this helper methods directly, 
  # they are wrapped in Lore's transaction routines. 
  #
  # See Lore::Transaction for examples. 
  module Transaction_Helpers

    def commit_transaction(tx)
      perform('COMMIT;')
    end

    def begin_transaction(tx)
      perform('BEGIN;')
    end

    def rollback_transaction(tx)
      if tx.last_savepoint then
        perform("ROLLBACK TO SAVEPOINT #{tx.last_savepoint};")
      else 
        perform('ROLLBACK;')
      end
    end

    def add_savepoint(tx)
      savepoint_name = "#{tx.context}_#{tx.depth}"
      perform("SAVEPOINT #{savepoint_name};")
      savepoint_name
    end
  
  end

end
end

