ActiveFedora.fedora.connection.send(:init_base_path)

puts "\n== Creating default collection types"
Hyrax::CollectionType.find_or_create_default_collection_type
Hyrax::CollectionType.find_or_create_admin_set_type

puts "\n== Loading workflows"
Hyrax::Workflow::WorkflowImporter.load_workflows
errors = Hyrax::Workflow::WorkflowImporter.load_errors
abort("Failed to process all workflows:\n  #{errors.join('\n  ')}") unless errors.empty?

puts "\n== Creating default admin set"
admin_set_id = AdminSet.find_or_create_default_admin_set_id

# I have found that when I come back to a development
# environment, that I may have an AdminSet in Fedora, but it is
# not indexed in Solr.  This remediates that situation by
# ensuring we have an indexed AdminSet
puts "\n== Ensuring the found or created admin set is indexed"
AdminSet.find(admin_set_id).update_index

