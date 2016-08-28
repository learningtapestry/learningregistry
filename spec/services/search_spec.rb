require 'services/search'
require_relative '../support/shared_contexts/envelopes_for_search'

describe MR::Search, type: :service do
  include_context 'envelopes for search'

  it 'filter params on initialize' do
    params = { per_page: 10, page: 2, something: 'bla' }
    search = MR::Search.new(params)
    expect(search.params.keys).to eq(['something'])
  end

  it 'empty params return a match all query' do
    all_count = Envelope.count
    expect(all_count).to be > 0

    search_count = MR::Search.new({}).run.count
    expect(search_count).to eq all_count
  end

  it 'extract fts param' do
    expect(MR::Search.new(fts: 'something').fts).to eq 'something'
  end

  it 'extract community param' do
    expect(MR::Search.new(envelope_community: 'Comm').community).to eq 'comm'
    expect(MR::Search.new(community: 'diff-comm').community).to eq 'diff_comm'
    expect(MR::Search.new(community: '').community).to be_nil
  end

  it 'extract type param' do
    expect(MR::Search.new(type: 'paradata').type).to eq 'paradata'
  end

  it 'extract resource_type param' do
    expect(
      MR::Search.new(community: 'learning_registry',
                     resource_type: 'anything')
                .resource_type
    ).to be_nil

    expect(
      MR::Search.new(community: 'credential_registry',
                     resource_type: 'organization')
                .resource_type
    ).to eq '{"@type":"ctdl:Organization"}'
  end

  it 'extract date_range param' do
    range = MR::Search.new(from: '2016-08-25T00:00:00Z',
                           until: '2016-08-27T23:59:59Z').date_range

    expect(range[:from]).to be_a_kind_of(Time)
    expect(range[:from]).to eq Chronic.parse('2016-08-25T00:00:00Z')
    expect(range[:until]).to be_a_kind_of(Time)
    expect(range[:until]).to eq Chronic.parse('2016-08-27T23:59:59Z')
  end

  it 'date_range parse natural language terms' do
    range = MR::Search.new(from: 'february 1st',
                           until: '3 days ago').date_range

    expect(range[:from]).to be_a_kind_of(Time)
    expect(range[:until]).to be_a_kind_of(Time)
    expect([range[:from].day, range[:from].month]).to eq([1, 2])
  end

  it 'date_range is a compact hash' do
    range = MR::Search.new(from: '', until: '3 days ago').date_range
    expect(range[:from]).to be_nil

    range = MR::Search.new(from: '', until: nil).date_range
    expect(range).to be_nil
  end

  it 'search by fts partials (name)' do
    res = MR::Search.new(fts: 'philos').run
    expect(res.first.processed_resource['name']).to(
      eq('Harry Potter and the Philosopher\'s Stone')
    )
  end

  it 'search by fts full words (desc)' do
    res = MR::Search.new(fts: 'Hogwarts').run
    expect(res.first.processed_resource['description']).to(
      include('Hogwarts School of Witchcraft and Wizardry')
    )
  end
end
