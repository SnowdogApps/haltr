require 'redmine'

Rails.logger.info 'Starting haltr plugin'

require 'haltr'

# Haltr has plugins of his own
# similar to config/initializers/00-core_plugins.rb in Redmine
# Loads the core plugins located in lib/plugins
Dir.glob(File.join(File.dirname(__FILE__), "lib/plugins/*")).sort.each do |directory|
  if File.directory?(directory)
    lib = File.join(directory, "lib")
    if File.directory?(lib)
      $:.unshift lib
      ActiveSupport::Dependencies.autoload_paths += [lib]
    end
    initializer = File.join(directory, "init.rb")
    if File.file?(initializer)
      config = config = RedmineApp::Application.config
      eval(File.read(initializer), binding, initializer)
    end
  end
end

Date::DATE_FORMATS[:ddmmyy] = "%d%m%y"

require_dependency 'utils'
require_dependency 'iso_countries'
require_dependency File.expand_path(File.join(File.dirname(__FILE__), 'app/models/export_channels'))

if (Redmine::VERSION::MAJOR == 1 and Redmine::VERSION::MINOR >= 4) or Redmine::VERSION::MAJOR == 2
  require_dependency 'country_iso_translater'
else
  config.gem 'sundawg_country_codes', :lib => 'country_iso_translater'
  config.gem 'money', :version => '>=5.0.0'
end

Rails.configuration.to_prepare do
  Project.send(:include, ProjectHaltrPatch)
end

Redmine::Plugin.register :haltr do
  name 'haltr'
  author 'Ingent'
  description 'Hackers dont do books'
  version '1.2'

  settings :default => {
    'trace_url' => 'http://localhost:3000',
    'export_channels_path' => '/tmp',
    'issues_controller_name' => 'issues',
    'default_country' => 'es',
    'default_currency' => 'EUR',
    'hide_unauthorized' => '1'
  },
  :partial => '/common/settings'

  project_module :haltr do
    permission :general_use,
      { :clients  => [:index, :new, :edit, :create, :update, :destroy, :check_cif, :link_to_profile, :unlink,
                      :allow_link, :deny_link],
        :people   => [:index, :new, :show, :edit, :create, :update, :destroy],
        :invoices => [:index, :new, :edit, :create, :update, :destroy, :show, :mark_sent, :mark_closed, :mark_not_sent,
                      :mark_accepted, :mark_accepted_with_mail, :mark_refused, :mark_refused_with_mail, :destroy_payment,
                      :facturae30, :facturae31, :facturae32, :peppolubl20, :send_invoice, :log, :legal, :update_currency_select,
                      :amend_for_invoice, :download_new_invoices, :send_new_invoices, :duplicate_invoice, :biiubl20, 
                      :svefaktura, :oioubl20],
        :received => [:index, :new, :edit, :create, :update, :destroy, :show],
        :tasks    => [:index, :n19, :n19_done, :report, :import_aeb43],
        :companies => [:index,:edit,:update,:linked_to_mine]},
      :require => :member

    permission :manage_payments, { :payments => [:index, :new, :edit, :create, :update, :destroy ] }, :require => :member
    permission :use_templates, { :invoice_templates => [:index, :new, :edit, :create, :update, :destroy, :show, :new_from_invoice,
                                 :invoices, :create_invoices, :update_taxes] }, :require => :member

    permission :batch_processes, { :tasks => [:automator] }, :require => :member

    # Loads permisons from config/channels.yml
    ExportChannels.permissions.each do |permission,actions|
      permission permission, actions, :require => :member
    end

  end

  menu :project_menu, :haltr_community, { :controller => 'clients', :action => 'index' }, :caption => :label_companies
  menu :project_menu, :haltr_invoices, { :controller => 'invoices', :action => 'index' }, :caption => :label_invoice_plural
  menu :project_menu, :haltr_payments, { :controller => 'payments', :action => 'index' }, :caption => :label_payment_plural
  menu :top_menu, :admin_haltr_stastics, { :controller => 'stastics', :action => 'index' }, :caption => :label_stastics, :if => Proc.new {User.current.admin?}

end

# avoid taxis error
ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular 'taxes', 'tax'
end
