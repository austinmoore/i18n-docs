
namespace :i18n do

  desc "Find and list translation keys that do not exist in all locales"
  task :missing_keys => :environment do
    finder = LocalchI18n::MissingKeysFinder.new(I18n.backend)
    finder.find_missing_keys
  end

  desc "Download translations from Google Spreadsheet and save them to YAML files."
  task :import_translations => :environment do
    raise "'Rails' not found! Tasks can only run within a Rails application!" if !defined?(Rails)

    config_file = Rails.root.join('config', 'translations.yml')
    raise "No config file 'config/translations.yml' found." if !File.exists?(config_file)

    tmp_dir = Rails.root.join('tmp')
    Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)

    translations = LocalchI18n::Translations.new(config_file, tmp_dir)
    translations.download_files
    translations.store_translations
    translations.clean_up

  end

  desc "Export all language files to CSV files (only files contained in en folder are considered)"
  task :export_translations => :environment do
    # raise "'Rails' not found! Tasks can only run within a Rails application!" if !defined?(Rails)

    source_dir  = ENV['source_dir'] || Rails.root.join('config', 'locales')
    output_dir  = ENV['output_dir'] || Rails.root.join('tmp')
    locale     =  ENV['locale'] || :en

    input_files = Dir[File.join(source_dir, "**/*.#{locale}.yml")] +
      Dir[File.join(source_dir, "**/#{locale}.yml")]

    puts ""
    puts "  Detected locale: #{locale}"
    puts "  Detected files:"
    input_files.each {|f| puts "    * #{File.basename(f)}" }

    puts ""
    puts "  Start exporting files:"

    input_files.each do |file|
      relative_path = Pathname.new(file).relative_path_from(Pathname.new(source_dir)).to_s.gsub('.yml', '.csv')
      output_file = File.join(output_dir, "export_translations", relative_path)
      exporter = LocalchI18n::TranslationFileExport.new(file, output_file, [locale])
      exporter.export
    end

    puts ""
    puts "  CSV files can be removed safely after uploading them manually to Google Spreadsheet."
    puts ""
  end

end


