require_relative "test_helper"

class BasicSchedulerTest < Minitest::Test
  def test_works
    people = [
      {
        availability: [
          {starts_at: Time.parse("2020-01-01 08:00:00"), ends_at: Time.parse("2020-01-01 16:00:00")},
          {starts_at: Time.parse("2020-01-02 08:00:00"), ends_at: Time.parse("2020-01-02 16:00:00")}
        ],
        max_hours: 8
      },
      {
        availability: [
          {starts_at: Time.parse("2020-01-02 08:00:00"), ends_at: Time.parse("2020-01-02 16:00:00")},
          {starts_at: Time.parse("2020-01-03 08:00:00"), ends_at: Time.parse("2020-01-03 16:00:00")}
        ],
        max_hours: 8
      },
      {
        availability: [
          {starts_at: Time.parse("2020-01-01 08:00:00"), ends_at: Time.parse("2020-01-01 16:00:00")}
        ],
        max_hours: 8
      },
      {
        availability: [
          {starts_at: Time.parse("2020-01-04 08:00:00"), ends_at: Time.parse("2020-01-04 16:00:00")}
        ],
        max_hours: 7
      }
    ]

    shifts = [
      {starts_at: Time.parse("2020-01-01 08:00:00"), ends_at: Time.parse("2020-01-01 16:00:00")},
      {starts_at: Time.parse("2020-01-02 08:00:00"), ends_at: Time.parse("2020-01-02 15:30:00")},
      {starts_at: Time.parse("2020-01-03 08:00:00"), ends_at: Time.parse("2020-01-03 16:00:00")},
      {starts_at: Time.parse("2020-01-04 08:00:00"), ends_at: Time.parse("2020-01-04 16:30:00")}
    ]

    scheduler = ORTools::BasicScheduler.new(people: people, shifts: shifts)
    expected = [
      {person: 2, shift: 0},
      {person: 0, shift: 1},
      {person: 1, shift: 2}
    ]
    assert_equal expected, scheduler.assignments
    assert_equal 23.5, scheduler.assigned_hours
    assert_equal 32, scheduler.total_hours
  end
end
