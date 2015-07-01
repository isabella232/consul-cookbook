require 'spec_helper'

describe_recipe 'consul::default' do
  context 'with default attributes' do
    cached(:chef_run) { ChefSpec::ServerRunner.new(step_into: %w{consul_config}).converge(described_recipe) }

    it { expect(chef_run).not_to include_recipe('chef-vault::default') }
    it { expect(chef_run).to create_file('/etc/consul.json').with(owner: 'consul', group: 'consul') }

    it 'converges successfully' do
      chef_run
    end
  end

  context 'with verify_incoming & verify_outgoing = true' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(step_into: %w{consul_config}) do |node, server|
        server.create_data_bag('secrets', {
          'consul' => {
            'ca_certificate' => 'foo',
            'certificate' => 'bar',
            'private_key' => 'baz'
          }
        })

        node.set['consul']['config']['verify_incoming'] = true
        node.set['consul']['config']['verify_outgoing'] = true
      end.converge(described_recipe)
    end

    it { expect(chef_run).to include_recipe('chef-vault::default') }
    it { expect(chef_run).to create_directory('/etc/consul.d/ssl/certs') }
    it { expect(chef_run).to create_directory('/etc/consul.d/ssl/private') }
    it { expect(chef_run).to create_directory('/etc/consul.d/ssl/CA') }

    it { expect(chef_run).to create_file('/etc/consul.json').with(owner: 'consul', group: 'consul') }

    it do
      expect(chef_run).to create_file('/etc/consul.d/ssl/CA/consul.crt')
      .with(content: 'foo')
      .with(owner: 'consul')
      .with(group: 'consul')
    end

    it do
      expect(chef_run).to create_file('/etc/consul.d/ssl/certs/consul.crt')
      .with(content: 'bar')
      .with(owner: 'consul')
      .with(group: 'consul')
      .with(mode: '0644')
    end

    it do
      expect(chef_run).to create_file('/etc/consul.d/ssl/private/consul.key')
      .with(content: 'baz')
      .with(sensitive: true)
      .with(owner: 'consul')
      .with(group: 'consul')
      .with(mode: '0640')
    end

    it 'converges successfully' do
      chef_run
    end
  end
end
