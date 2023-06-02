# frozen_string_literal: true

require 'sequel'
require 'logger'
# Delete DATABASE_URL from the environment, so it isn't accidently
# passed to subprocesses.  DATABASE_URL may contain passwords.
DB = Sequel.connect ENV.delete 'DATABASE_URL'

DB.loggers << Logger.new($stdout)
