# Copyright (c) 2005 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module SslRequirement
  def self.included(controller)
    controller.extend(ClassMethods)
    controller.before_filter(:ensure_proper_protocol)
  end

  module ClassMethods
    # Specifies that the named actions requires an SSL connection to be performed (which is enforced by ensure_proper_protocol).
    def ssl_required(*actions)
      write_inheritable_array(:ssl_required_actions, actions.flatten)
    end

    def ssl_allowed(*actions)
      write_inheritable_array(:ssl_allowed_actions, actions.flatten)
    end
  end

  protected

  # Returns true if the current action is supposed to run as SSL
  def ssl_required?
    actions = self.class.read_inheritable_attribute(:ssl_required_actions)
    SslRequirement.actions_include_action?( actions, params[:action])
  end

  def ssl_allowed?
    actions = self.class.read_inheritable_attribute(:ssl_allowed_actions)
    SslRequirement.actions_include_action?( actions, params[:action])
  end

  private

  def ensure_proper_protocol
    must_turn_on = (not request.ssl? and ssl_required?)
    must_turn_off = (request.ssl? and not ssl_allowed? and not ssl_required?)

    return if not must_turn_on and not must_turn_off

    protocol = (must_turn_on ? 'https' : 'http')
    redirect_to "#{protocol}://#{request.host}#{request.request_uri}"
    flash.keep
    return false
  end

  def self.actions_include_action?(actions, action)
    actions = (actions || [])
    actions = [:all] if actions.empty?
    return true if actions.include? :all
    actions.map(&:to_sym).include?(action.to_sym)
  end
end