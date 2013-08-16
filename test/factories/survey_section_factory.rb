FactoryGirl.define do
  
  sequence(:survey_section_display_order) { |n| n }

  factory :survey_section do |s|
    s.association :survey # s.survey_id                 {}
    s.title { "Demographics" }
    s.description { "Asking you about your personal data" }
    s.display_order { FactoryGirl.generate :survey_section_display_order }
    s.reference_identifier { "demographics" }
    s.data_export_identifier { "demographics" }

    factory :survey_section_with_mandatory_question do |s|
      after(:create) do |s, evaluator|
        FactoryGirl.create(:question, survey_section: s)
        FactoryGirl.create(:mandatory_question, survey_section: s)
     end
    end

    factory :survey_section_with_required_question do |s|
      after(:create) do |s, evaluator|
        FactoryGirl.create(:question, survey_section: s)
        FactoryGirl.create(:requirement, survey_section: s)
     end
    end

  end

end