# frozen_string_literal: true
FactoryBot.define do
  factory :hospital do
    name { Faker::Company.name }
    code { Faker::Alphanumeric.unique.alpha(number: 6).upcase }
  end
end
