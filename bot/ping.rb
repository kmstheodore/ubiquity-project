require "google/cloud/tasks"
require "googleauth"
require "net/http"
require "uri"
require "json"

# Create a Task with an HTTP Target
#
# @param [String] project_id Your Google Cloud Project ID.
# @param [String] location_id Your Google Cloud Project Location ID.
# @param [String] queue_id Your Google Cloud Tasks Queue ID.
# @param [String] task_list_id Your Google Tasks List ID.
# @param [String] task_title The title of the task to be created.
# @param [String] task_notes The notes for the task to be created.
# @param [Integer] seconds The delay, in seconds, to process your task.
def create_http_task(project_id, location_id, queue_id, task_list_id, task_title, task_notes, seconds: nil)
  # Instantiates a client.
  client = Google::Cloud::Tasks.cloud_tasks

  # Construct the fully qualified queue name.
  parent = client.queue_path project: project_id, location: location_id, queue: queue_id

  # Construct the task payload.
  payload = {
    title: task_title,
    notes: task_notes
  }

  # Get OAuth 2.0 token.
  scope = "https://www.googleapis.com/auth/tasks"
  authorizer = Google::Auth.get_application_default([scope])
  token = authorizer.fetch_access_token!["access_token"]

  # Construct the HTTP request.
  url = "https://tasks.googleapis.com/tasks/v1/lists/#{task_list_id}/tasks"
  task = {
    http_request: {
      http_method: "POST",
      url: url,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json"
      },
      body: payload.to_json
    }
  }

  # Add schedule time if delay is specified.
  if seconds
    timestamp = Google::Protobuf::Timestamp.new
    timestamp.seconds = Time.now.to_i + seconds.to_i
    task[:schedule_time] = timestamp
  end

  # Send create task request.
  response = client.create_task parent: parent, task: task

  puts "Created task #{response.name}" if response.name
end

# Example usage
create_http_task("ubiquity-project-440912", "your-location-id", "your-queue-id", "your-task-list-id", "Task Title", "Task Notes", seconds: 60)
