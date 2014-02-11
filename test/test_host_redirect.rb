# encoding: UTF-8
require 'rubygems'
require 'test/unit'
require "rack/test"
require 'rack-host-redirect'


INNER_APP = Proc.new { [200, {}, ['OK']] }


class TestHostRedirect < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Rack::HostRedirect.new(INNER_APP, {
      'www.FOO.com' => 'www.bar.com',
      'LOOP.foo.com' => 'Loop.foo.com', # test no redirects to same host
      %w(one.foo.com two.foo.com) => 'three.foo.com'
    })
  end

  def test_host_redirect
    get '/one', {'two' => 'three'}, 'HTTP_HOST' => 'www.foo.COM'
    assert_equal 301, last_response.status
    assert_equal 'http://www.bar.com/one?two=three', last_response['location']
    follow_redirect!
    assert last_response.ok?
    get '/one', {'two' => 'three'}, 'HTTP_HOST' => 'www.baz.com'
    assert last_response.ok?

    get '/one', {'two' => 'three'}, 'HTTP_HOST' => 'one.foo.COM'
    assert_equal 301, last_response.status
    assert_equal 'http://three.foo.com/one?two=three', last_response['location']
  end

  def test_prefers_x_forwarded_host_when_available
    env = {'HTTP_HOST' => 'localhost', 'SERVER_NAME' => 'localhost', 'SERVER_PORT' => '3000'}
    get '/one', {'two' => 'three'}, env
    assert last_response.ok?
    get '/one', {'two' => 'three'}, env.merge('HTTP_X_FORWARDED_HOST' => 'www.foo.com')
    assert_equal 301, last_response.status
    assert_equal 'http://www.bar.com/one?two=three', last_response['location']
  end

  def test_does_not_redirect_to_current_host
    get '/one', {'two' => 'three'}, 'HTTP_HOST' => 'loop.foo.COM'
    assert last_response.ok?
  end
end
