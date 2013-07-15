require "open-uri"
require "json"
require "awesome_print"
issue_number = ARGV[0]
issue = open "https://drupal.org/node/#{issue_number}/project-issue/json" do |json|
    JSON.load json
end
# Add comment numbers to comments
issue["comments"].each do |id, comment|
    comment["comment_number"] = comment["subject"][/#([0-9]+)/, 1].to_i
end
# Convert the attachments from a hash to a array.
issue["attachments"] = issue["attachments"].values
# Drop non-patch attachments because we don't need them.
issue["attachments"].select! do |attachment|
    attachment["urls"].select! do |url|
        !(url =~ /\.patch$/)
    end
    attachment["urls"].size != 0
end
# Sort attachments by comment order
issue["attachments"].sort_by! do |attatchment|
    attatchment["comment_number"]
end
