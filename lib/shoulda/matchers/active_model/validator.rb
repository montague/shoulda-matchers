module Shoulda
  module Matchers
    module ActiveModel
      class Validator
        include Helpers

        attr_accessor :record, :context, :strict

        def initialize(attribute)
          @attribute = attribute
          @detected_range_error = false
          reset
        end

        def reset
          @messages = nil
        end

        def allow_description(allowed_values)
          if strict?
            "doesn't raise when #{attribute} is set to #{allowed_values}"
          else
            "allow #{attribute} to be set to #{allowed_values}"
          end
        end

        def expected_message_from(attribute_message)
          if strict?
            "#{human_attribute_name} #{attribute_message}"
          else
            attribute_message
          end
        end

        def messages
          @messages ||= validation_exceptions_or_errors
        end

        def formatted_messages
          if exception_based?
            messages.map { |message| message.message }
          else
            messages
          end
        end

        def has_messages?
          messages.any?
        end

        def messages_description
          if exception_based?
            if has_messages?
              ": #{format_exception(messages.first).inspect}"
            else
              ' no exception'
            end
          else
            if has_messages?
              " errors:\n#{pretty_error_messages(record)}"
            else
              ' no errors'
            end
          end
        end

        def expected_messages_description(expected_message)
          if expected_message
            if strict?
              "exception to include #{expected_message.inspect}"
            else
              "errors to include #{expected_message.inspect}"
            end
          else
            if strict?
              "an exception to have been raised"
            else
              "errors"
            end
          end
        end

        def capture_range_error(error)
          @detected_range_error = true
          @messages = [error]
        end

        protected

        attr_reader :record, :attribute, :context

        private

        def strict?
          !!@strict
        end

        def detected_range_error?
          !!@detected_range_error
        end

        def exception_based?
          strict? || detected_range_error?
        end

        def validation_exceptions_or_errors
          if strict?
            validation_exceptions
          else
            validation_errors
          end
        # rescue RangeError => error
          # capture_range_error(error)
        end

        def validation_exceptions
          record.valid?(context)
          []
        rescue ::ActiveModel::StrictValidationFailed => exception
          [exception]
        end

        def validation_errors
          record.valid?(context)

          if record.errors.respond_to?(:[])
            record.errors[attribute]
          else
            record.errors.on(attribute)
          end
        end

        def format_exception(exception)
          if exception.is_a?(::ActiveModel::StrictValidationFailed)
            "#{exception.message}"
          else
            "#{exception.class}: #{exception.message}"
          end
        end

        def human_attribute_name
          record.class.human_attribute_name(attribute)
        end
      end
    end
  end
end
