class TimeSpan < ActiveTriples::Resource
  def initialize(uri = RDF::Node.new, _parent = ActiveTriples::Resource.new)
    uri = if uri.try(:node?)
            RDF::URI("#timespan_#{uri.to_s.gsub('_:', '')}")
          elsif uri.to_s.include?('#')
            RDF::URI(uri)
          end
    super
  end

  def persisted?
    !new_record?
  end

  def new_record?
    id.start_with?('#')
  end

  configure type: ::RDF::Vocab::EDM.TimeSpan
  property :start, predicate: ::RDF::Vocab::EDM.begin
  property :finish, predicate: ::RDF::Vocab::EDM.end
end
