# frozen_string_literal: true

module Jekyll
	module TestHarnessFixtures
		# Renders deterministic text so specs can assert Liquid tag integration.
		class FixtureGreetingTag < Liquid::Tag
			# Returns predictable output for integration assertions.
			def render(_context)
				'fixture-tag-output'
			end
		end
	end
end

Liquid::Template.register_tag('fixture_greeting', Jekyll::TestHarnessFixtures::FixtureGreetingTag)
