# frozen_string_literal: true

# Adds predictable document data so integration specs can verify hook execution.
Jekyll::Hooks.register :documents, :pre_render do |document|
	document.data['fixture_hook_marker'] = 'hooked-by-fixture'
end
