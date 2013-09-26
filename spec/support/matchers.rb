RSpec::Matchers.define :be_completed do
  match do |observer|
    observer.completed == true
  end
end

RSpec::Matchers.define :have_no_error do
  match do |observer|
    observer.error == nil
  end
end