begin
  require 'redmine'
  require 'haltr'

  RAILS_DEFAULT_LOGGER.info 'Starting haltr plugin'

  Date::DATE_FORMATS[:ddmmyy] = "%d%m%y"

  Redmine::Plugin.register :haltr do
    name 'haltr'
    author 'Ingent'
    description 'Hackers dont do books'
    version '0.1'

    project_module :haltr do
      permission :general_use,
        { :clients  => [:index, :new, :edit, :create, :update, :destroy],
          :people   => [:index, :new, :show, :edit, :create, :update, :destroy],
          :invoices => [:index, :new, :edit, :create, :update, :destroy, :showit, :pdf, :template, :mark_sent, :mark_closed, :mark_not_sent, :destroy_payment],
          :invoice_templates => [:index, :new, :edit, :create, :update, :destroy, :showit, :new_from_invoice],
          :tasks    => [:index, :create_more, :automator, :n19, :n19_done, :report, :import_aeb43],
          :payments => [:index, :new, :edit, :create, :update, :destroy ] },
        :require => :member
    end

    menu :project_menu, :haltr, { :controller => 'invoices', :action => 'index' }, :caption => 'Haltr'

  end

rescue MissingSourceFile
  RAILS_DEFAULT_LOGGER.info 'Warning: not running inside Redmine'
end

haltr_settings = ['company_name',
'company_tax_id',
'company_address',
'company_locality',
'company_postal_code',
'company_region',
'company_website',
'company_email',
'company_bank_account',
'company_logo_url']

haltr_settings.each do |hs|
  next if ProjectCustomField.find_by_name hs
  ProjectCustomField.new(:name=>hs,:field_format=>"string").save
end
