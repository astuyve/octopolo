arg :pull_request_id
desc 'Merges PR into the deployable branch'
command 'deployable' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/deployable'
    Octopolo::Scripts::Deployable.execute args.first
  end
end
