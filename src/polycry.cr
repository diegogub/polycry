require "json"
require "option_parser"

module Polycry
  VERSION = "0.1.0"

  CONFIG_FILE = ".poly.json"

  class Workspace
    include JSON::Serializable

    # TODO add configurable folders?

    @[JSON::Field(ignore: true)]
    property folders = ["components", "bases", "projects"]

    property components = Hash(String, String).new
    property bases = Hash(String, String).new
    property projects = Hash(String, String).new

    def load
      folders.each do |f|
        load_folder(f)
      end
    end

    def initialize
    end

    def save
      File.write(CONFIG_FILE, self.to_json)
    end

    def setup
      # try to create all folders in current workspace
      folders.each do |d|
        begin
          Dir.mkdir(d)
        rescue e
          puts e
        end
      end
    end

    def crystal_proj(type, path)
      system "crystal init #{type} #{path}"
      system "rm -Rf #{path}/.git #{path}/README.md #{path}/LICENSE"
    end

    def create_component(component)
      crystal_proj("lib", "components/#{component}")
    end

    def create_base(base)
      crystal_proj("lib", "bases/#{base}")
    end

    def create_project(proj)
      crystal_proj("app", "projects/#{proj}")
    end

    def create(object, params)
      case object
      when "component"
        create_component(params["name"])
      when "project"
        create_project(params["name"])
      when "base"
        create_base(params["name"])
      end
    end

    def load_folder(folder)
      begin
        d = Dir.new(folder)

        d.each_child do |o|
          case folder
          when "components"
            components[o] = ""
          when "bases"
            bases[o] = ""
          when "projects"
            projects[o] = ""
          end
        end
      rescue File::NotFoundError
        puts "No folder for #{folder}."
      end
    end
  end

  class Opts
    include JSON::Serializable

    def initialize
    end

    property subcommand = ""
    property obj = ""
    property params = Hash(String, String).new
  end

  workspace = Workspace.new
  if File.exists?(CONFIG_FILE)
    workspace = Workspace.from_json(File.read(CONFIG_FILE))
  end
  # load all folders that exist
  workspace.load

  options = Opts.new
  parser = OptionParser.new do |parser|
    parser.banner = "polycry [command] [component]"

    parser.on("-h", "--help", "Show this help") do
      puts parser
      exit
    end

    parser.invalid_option do |flag|
      STDERR.puts "ERROR: #{flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end

    parser.on("init", "init workspace") do
      options.subcommand = "init"
    end

    parser.on("info", "prints information on the Workspace") do
      options.subcommand = "info"
    end

    parser.on("create", "Create command.") do
      options.subcommand = "create"
      parser.on("component", "creates a component into the workspace") do
        options.obj = "component"
        parser.on("-n NAME", "--name=NAME", "Name for component") { |_name| options.params["name"] = _name }
      end

      parser.on("base", "Creates a base into the workspace") do
        options.obj = "base"
        parser.on("-n NAME", "--name=NAME", "Name for base") { |_name| options.params["name"] = _name }
      end

      parser.on("project", "Creates a project into the workspace") do
        options.obj = "project"
        parser.on("-n NAME", "--name=NAME", "Name for project") { |_name| options.params["name"] = _name }
      end

      parser.invalid_option do |flag|
        STDERR.puts "ERROR: #{flag} is not a valid option."
        STDERR.puts parser
        exit(1)
      end
    end
  end

  parser.parse

  case options.subcommand
  when "init"
    workspace.setup
    # save json config file
    workspace.save
  when "info"
    workspace.load
    puts workspace.to_json
    workspace.save
  when "create"
    case options.obj
    when "base", "project", "component"
      workspace.create(options.obj, options.params)
    else
      STDERR.puts "ERROR: invalid object to create: component,base,project"
      exit(1)
    end
  else
    STDERR.puts "ERROR: #{options.subcommand} is not a valid command."
    exit(1)
  end
end
