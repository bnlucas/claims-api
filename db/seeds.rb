# frozen_string_literal: true

require "faker"

# Use the 'faker' gem for realistic fake data. Add it to your Gemfile if you haven't already:
# gem 'faker', '~> 2.18', group: [:development, :test]

puts "Cleaning existing data..."
# Use `delete_all` for a fast, non-callback-invoking cleanup.
# Order is important due to foreign key constraints.
AuditLog.delete_all
Claim.delete_all
Customer.delete_all
puts "Done."

puts "Seeding database..."

# --- Customers ---
puts "Creating customers..."
# An array to hold all customers, including the hard-coded ones.
customers = []

# Create a known, standard customer for testing.
puts "Creating hard-coded test customers..."
customers << Customer.create!(
  id: "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  first_name: "John",
  last_name: "Doe",
  email: "johndoe@example.com",
  status: "active",
  )

# Create a second known customer for more complex testing scenarios.
customers << Customer.create!(
  id: "c7e2d93e-2f81-4b13-a442-88f5d02e071e",
  first_name: "Jane",
  last_name: "Doe",
  email: "janedoe@example.com",
  status: "active",
  )

# Create additional random customers to test general functionality.
8.times do |i|
  customers << Customer.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: "customer#{i + 1}@example.com",
    status: "active",
    )
end

# Create a few deleted customers for testing the `deleted?` scope
3.times do |i|
  customers << Customer.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: "inactive#{i + 1}@example.com",
    deleted_at: Faker::Time.backward(days: 30)
  )
end
puts "Created #{Customer.count} customers."

# --- Claims ---
puts "Creating claims..."
claim_types = %w[Medical Travel Vehicle Home]
statuses = %w[submitted processing approved rejected]

customers.each do |customer|
  # Create a bunch of claims for each customer
  rand(1..10).times do
    claim_type = claim_types.sample
    is_duplicate = [true, false].sample
    claim = Claim.create!(
      customer: customer,
      claim_type: claim_type,
      description: Faker::Lorem.paragraph(sentence_count: 2),
      amount_claimed: Faker::Number.decimal(l_digits: 4, r_digits: 2),
      status: statuses.sample,
      is_duplicate: is_duplicate
    )

    # Add a few soft-deleted claims
    if [true, false].sample
      claim.update_column(:deleted_at, Faker::Time.backward(days: 10))
    end
  end
end
puts "Created #{Claim.count} claims and #{AuditLog.count} audit logs."

puts "Seeding complete! 🎉"
