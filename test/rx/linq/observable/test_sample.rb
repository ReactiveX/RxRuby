require "#{File.dirname(__FILE__)}/../../../test_helper"

class TestObservableCreation < Minitest::Test
  include Rx::ReactiveTest

  def test_sampler_completes_first
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      scheduler.create_cold_observable(
        on_next(100, 1),
        on_next(200, 2),
        on_next(300, 3),
        on_next(400, 4),
        on_completed(600)
      ).sample(
        scheduler.create_cold_observable(
          on_next(50, 1),
          on_next(150, 1),
          on_next(350, 1),
          on_completed(400)
        )
      )
    end

    msgs = [
      on_next(SUBSCRIBED + 150, 1),
      on_next(SUBSCRIBED + 350, 3),
      on_completed(600)
    ]
    assert_messages msgs, res.messages
  end

  def test_source_completes_first
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      scheduler.create_cold_observable(
        on_next(100, 1),
        on_completed(200)
      ).sample(
        scheduler.create_cold_observable(
          on_next(50, 1),
          on_next(150, 1),
          on_completed(400)
        )
      )
    end

    msgs = [
      on_next(SUBSCRIBED + 150, 1),
      on_completed(400)
    ]
    assert_messages msgs, res.messages
  end

  def test_with_recipe
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      scheduler.create_cold_observable(
        on_next(100, 'left'),
        on_completed(200)
      ).sample(
        scheduler.create_cold_observable(
          on_next(150, 'right'),
          on_completed(200)
        )
      ) { |left, right| [left, right] }
    end

    msgs = [
      on_next(SUBSCRIBED + 150, ['left', 'right']),
      on_completed(400)
    ]
    assert_messages msgs, res.messages
  end

  def test_source_errors
    # Verify unsubscribe sampler
    scheduler = Rx::TestScheduler.new

    sampler = nil
    res = scheduler.configure do
      sampler = scheduler.create_cold_observable(
        on_next(50, 1),
        on_completed(200)
      )

      scheduler.create_cold_observable(
        on_error(100, 'badness')
      ).sample(sampler)
    end

    msgs = [on_error(SUBSCRIBED + 100, 'badness')]
    assert_messages msgs, res.messages
  end

  def test_sampler_errors
    # Verify unsubscribe source
    scheduler = Rx::TestScheduler.new

    sampler = nil
    res = scheduler.configure do
      sampler = scheduler.create_cold_observable(
        on_error(50, 'badness'),
        on_completed(200)
      )

      scheduler.create_cold_observable(
        on_next(100, 1)
      ).sample(sampler)
    end

    msgs = [on_error(250, 'badness')]
    assert_messages msgs, res.messages
  end
end
