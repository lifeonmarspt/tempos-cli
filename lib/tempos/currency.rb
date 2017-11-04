module Tempos
  module Currency
    class Invalid < StandardError
    end

    def self.valid_currencies
      [
        'HOURS',
        'EUR',
        'GBP',
        'USD',
      ]
    end

    def self.normalize currency
      currency = currency.upcase
      currency = "hours" if currency == "hour"

      valid_currencies.include? currency or raise Invalid
      currency
    end
  end
end
