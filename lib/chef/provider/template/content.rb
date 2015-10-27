#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/mixin/template'
require 'chef/file_content_management/content_base'

class Chef
  class Provider
    class Template

      class Content < Chef::FileContentManagement::ContentBase

        include Chef::Mixin::Template

        def template_location
          @template_file_cache_location ||= begin
            template_finder.find(new_resource.source, :local => new_resource.local, :cookbook => new_resource.cookbook)
          end
        end

        private

        def file_for_provider
          context = TemplateContext.new(new_resource.variables)
          context[:node] = run_context.node
          context[:template_finder] = template_finder

          # helper variables
          context[:cookbook_name] = new_resource.cookbook_name unless context.keys.include?(:coookbook_name)
          context[:recipe_name] = new_resource.recipe_name unless context.keys.include?(:recipe_name)
          context[:recipe_line_string] = new_resource.source_line unless context.keys.include?(:recipe_line_string)
          context[:recipe_path] = new_resource.source_line_file unless context.keys.include?(:recipe_path)
          context[:recipe_line] = new_resource.source_line_number unless context.keys.include?(:recipe_line)
          context[:template_name] = new_resource.source unless context.keys.include?(:template_name)
          context[:template_path] = template_location unless context.keys.include?(:template_path)

          context._extend_modules(new_resource.helper_modules)
          output = context.render_template(template_location)

          tempfile = Chef::FileContentManagement::Tempfile.new(new_resource).tempfile
          tempfile.binmode
          tempfile.write(output)
          tempfile.close
          tempfile
        end

        def template_finder
          @template_finder ||= begin
            TemplateFinder.new(run_context, new_resource.cookbook_name, run_context.node)
          end
        end
      end
    end
  end
end
