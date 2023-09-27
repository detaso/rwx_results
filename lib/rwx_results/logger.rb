module RwxResults
  class Logger
    AnnotationProperties = Struct.new(
      "AnnotationProperties",
      :title,
      :file,
      :line,
      :end_line,
      :col,
      :end_column,
      keyword_init: true
    )

    def add_annotation(level:, properties:, message:)
      args =
        AnnotationProperties.new(**properties)

      issue_command(
        command: level,
        properties: args.to_h,
        message:
      )
    end

    %i[notice warning error].each do |level|
      define_method(level) do |properties:, message:|
        add_annotation(level:, properties:, message:)
      end
    end

    def add_message(level:, message:)
      if level == :debug
        return unless debug?

        issue_command(
          command: :debug,
          message:
        )
      else
        # Assume info
        add_output message
      end
    end

    %i[debug info].each do |level|
      define_method(level) do |message:|
        add_message(level:, message:)
      end
    end

    def debug?
      ENV["RUNNER_DEBUG"] == "1"
    end

    def issue_command(command:, properties: {}, message: nil)
      cmd = "::#{command.to_s.tr("_", "-")}"

      args =
        properties.map do |k, v|
          next if v.nil? || v.to_s.empty?

          "#{k}=#{escape_property(v)}"
        end.compact

      unless args.empty?
        cmd += " "
        cmd += args.join(",")
      end

      cmd += "::#{escape_data(message)}"

      add_output cmd
    end

    private

    def add_output(str)
      if ENV.key?("GITHUB_OUTPUT")
        File.open(ENV["GITHUB_OUTPUT"], "a") do |f|
          f.puts str
        end
      else
        puts str
      end
    end

    def escape_data(data)
      return "" if data.nil?

      data
        .to_s
        .gsub(/%/, "%25")
        .gsub(/\r/, "%0D")
        .gsub(/\n/, "%0A")
    end

    def escape_property(prop)
      return "" if prop.nil?

      prop
        .to_s
        .gsub(/%/, "%25")
        .gsub(/\r/, "%0D")
        .gsub(/\n/, "%0A")
        .gsub(/:/, "%3A")
        .gsub(/,/, "%2C")
    end
  end
end
