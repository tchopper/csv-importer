module CSVImporter
  # Do the actual import.
  #
  # It iterates over the rows' models and persist them. It returns a `Report`.
  class Validater
    def self.call(*args)
      new(*args).call
    end

    include Virtus.model

    attribute :rows, Array[Row]
    attribute :when_invalid, Symbol
    attribute :after_save_blocks, Array[Proc], default: []

    attribute :report, Report, default: proc { Report.new }

    ImportAborted = Class.new(StandardError)

    # Persist the rows' model and return a `Report`
    def call
      p "validater"
      if rows.empty?
        report.done!
        return report
      end

      report.in_progress!

      validate_rows!

      report.done!
      report
    rescue ImportAborted
      report.aborted!
      report
    end

    private

    def abort_when_invalid?
      when_invalid == :abort
    end

    def validate_rows!
      p "validating each row"

      rows.each_with_index do |row, index|
        after_save_blocks.each { |block| block.call(row.model) }
        record = row.model
        if !record.valid?
          add_to_report(record)
        end
      end

    end

    def add_to_report(row)
      report.validated_rows << row
    end

    def transaction(&block)
      rows.first.model.class.transaction(&block)
    end
  end
end
