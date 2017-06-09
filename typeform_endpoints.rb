require 'sinatra'
require 'json'
require 'slack-ruby-client'
require 'yaml'
require 'rest-client'

set :port, 4567

$welcome_typeform_ids = {
  form_id: 'rElE8H',
  first_name_id: 'qgXp',
  last_name_id: 'URU1',
  email_id: '48527284',
  company_id: 'cbuh',
  legal_id: '48527512',
  person_id: 'wbMx'
}

$my_typeform_api_key = ENV["TYPEFORM_API_KEY"]

$slack_api_token = ENV["SLACK_API_TOKEN"]

$people = YAML.load_file('typeformers.yml')

get '/health' do
  [200, 'OK']
end

post '/update_typecoin_multiple_choice' do
  response = JSON.parse(request.body.read)
  answers = response['form_response']['answers']
  multiple_choice_answer = answers.find { |answer| answer['field'] == { "id" => "oIrj", "type" => "multiple_choice" } }

  new_choice = nil
  if multiple_choice_answer['choice'].key?('other')
    new_choice = multiple_choice_answer['choice']['other']
  end

  unless new_choice.nil?
    form = JSON.parse(RestClient.get('https://api.typeform.com/forms/mO3Zdn', headers = { 'Content-Type' => 'application/json', 'X-Typeform-Key' => $my_typeform_api_key }))
    multiple_choice = form['fields'].find { |field| field['id'] == 'oIrj' }
    choices = multiple_choice['properties']['choices']
    choices << { 'label' => new_choice }
    RestClient.put('https://api.typeform.com/forms/mO3Zdn', form.to_json, headers = { 'Content-Type' => 'application/json', 'X-Typeform-Key' => $my_typeform_api_key })
  end

  [200, 'OK']
end

post '/signin' do
  response = JSON.parse(request.body.read)
  form_id = response['form_response']['form_id']

  halt 403 unless form_id == $welcome_typeform_ids.fetch(:form_id)

  answers = response['form_response']['answers']

  first_name_object = answers.select { |answer| answer['field']['id'] == $welcome_typeform_ids.fetch(:first_name_id) }
  first_name = first_name_object.first.fetch('text')

  last_name_object = answers.select { |answer| answer['field']['id'] == $welcome_typeform_ids.fetch(:last_name_id) }
  last_name = last_name_object.first.fetch('text')

  company_object = answers.select { |answer| answer['field']['id'] == $welcome_typeform_ids.fetch(:company_id) }
  company = company_object.first.fetch('text')

  person_object = answers.select { |answer| answer['field']['id'] == $welcome_typeform_ids.fetch(:person_id) }
  person = person_object.first.fetch('choice').fetch('label')

  person_slack = $people.key(person)

  $web_client = Slack::Web::Client.new(token: $slack_api_token)

  $web_client.chat_postMessage(
    channel: '@' + person_slack,
    text: 'Hello ' + person + '! ' + first_name + ' ' + last_name + ' from ' + company + ' is here to see you. Make your way to Barception!',
    username: 'Welcome Bot',
    icon_emoji: ':wave:'
  )

  [200, 'OK']
end
