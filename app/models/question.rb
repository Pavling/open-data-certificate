class Question < ActiveRecord::Base
  include Surveyor::Models::QuestionMethods

  attr_accessible :requirement, :required, :help_text_more_url

  scope :excluding, lambda { |*objects| where(['questions.id NOT IN (?)', (objects.flatten.compact << 0)]) }

  before_validation :set_default_value_for_required
  after_save :update_mandatory

  validate :required_is_not_nil # don't let requirement be null, as we're querying the DB for it in the Survey

  def requirement_level
    # Definition: The level to which the current question is assigned. This is used to determine the level for achieved
    #             and outstanding requirements, and for the display customisation of questions.
    #TODO: Create an association to a model for Improvements? Or just leave it as a text key for the translations?
    @requirement_level ||= requirement.to_s.match(/^[a-zA-Z]*/).to_s
  end

  def requirement_level_index
    @requirement_level_index ||= Survey::REQUIREMENT_LEVELS.index(requirement_level)
  end

  def is_a_requirement?
    # Definition: A 'Requirement' is an bar that needs to be passed to contribute to attaining a certain level in the questionnaire.
    #             This is not the same as being "required" - which is about whether a question is mandatory to be completed.
    #             For the moment, requirements are stored in the DB as labels with a 'requirement' attribute set.
    @is_a_requirement ||= display_type == 'label' && !requirement.blank?
  end

  def question_corresponding_to_requirement
    @question_corresponding_to_requirement ||= survey_section.survey.only_questions.detect{|q|q.requirement == requirement}
  end

  def answer_corresponding_to_requirement
    @answer_corresponding_to_requirement ||= survey_section.survey.only_questions.map(&:answers).flatten.detect{|a|a.requirement == requirement}
  end

  def requirement_met_by_responses?(responses)
    # could use thusly to get all the displayed requirements for a survey and whether they have been met by their corresponding answers:
    #   `response_set.survey.questions.flatten.select{|e|e.is_a_requirement? && e.triggered?(response_set)}.map{|e|[e.requirement, e.requirement_met_by_responses?(rs.responses)]}`
    @requirement_met_by_responses ||= calculate_if_requirement_met_by_responses(responses)
  end

  def dependent?
    @dependent_q ||= self.dependency(includes: :dependency_conditions) != nil
  end

  def triggered?(response_set)
    @triggered_q ||= (dependent? ? self.dependency(includes: :dependency_conditions).is_met?(response_set) : true)
  end

  private
  def calculate_if_requirement_met_by_responses(responses)
    # NOTE: At the moment, there is an expectation that each requirement is associated to only one question or answer in
    #       a survey
    #       If a requirement is tied to more that one question or answer, then the calculation of whether it's met needs
    #       to be more comprehensive - it would have to ensure that *every* occurrence of the requirement has been met to
    #       definitively say the requirement has been met.
    #       Validation in the Survey model is used to prevent a requirement getting linked to more than one question or answer
    question = answer_corresponding_to_requirement.try(:question) || question_corresponding_to_requirement

    response_level_index = case question.pick
                             when 'one'
                               responses.where(:question_id => question.id).map(&:requirement_level_index).max # for radio buttons, the achieved level supersedes lower levels, so return the max level of all the responses to the question
                             else
                               responses.joins(:answer).where(["responses.question_id = ? AND answers.requirement = ?", question.id, requirement]).first.try(:requirement_level_index) # for everything else, get the requirement level for the response for the requirement in the
                           end

    !!(response_level_index.to_i >= requirement_level_index)
  end

  private
  def update_mandatory
    #TODO: swap to using an observer instead?
    self.is_mandatory ||= required.present?
    Question.update(id, :is_mandatory => is_mandatory) if is_mandatory_changed?
  end

  private
  def set_default_value_for_required
    self.required ||= ''
  end

  private
  def required_is_not_nil
    errors.add(:required, 'should not be nil') if required.nil?
  end
end
