# Cookbook Name:: db
#
# Copyright (c) 2011 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

rs_utils_marker :begin

DATA_DIR = node[:db][:data_dir]

log "  Verify if database state is 'uninitialized'..."
db_init_status :check do
  expected_state :uninitialized
  error_message "Database already initialized.  To over write existing database run do_force_reset before this recipe"
end

log "  Stopping database..."
db DATA_DIR do
  action :stop
end

log "  Creating block device..."
block_device DATA_DIR do
  lineage node[:db][:backup][:lineage]
  action :create
end

log "  Moving database to block device and starting database..."
db DATA_DIR do
  action [ :move_data_dir, :start ]
end

log "  Setting state of database to be 'initialized'..."
db_init_status :set

log "  Registering as master..."
db_register_master

log "  Adding replication privileges for this master database..."
include_recipe "db::setup_replication_privileges"

log "  Forcing a backup so slaves can init from this master..."
db_do_backup "do force backup" do
  force true
end

log "  Setting up cron to do scheduled backups..."
include_recipe "db::do_backup_schedule_enable"

rs_utils_marker :end
