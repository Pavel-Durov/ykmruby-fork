# Under yk the method lookup is an idempotent call keyed on `mrb_yk_method_version` (vm.c);
# this test checks that idempotent method lookup works when we define or remove a method dynamically.
#
# Run with: YKD_SERIALISE_COMPILATION=1 build/yk_build_config/bin/mruby <this file>
$iters = 2000

# Defining a method
klass = Class.new { def m; 1; end }
obj = klass.new
sum = 0
i = 0
while i < $iters
  klass.class_eval { def m; 2; end } if i == $iters / 2
  sum += obj.m
  i += 1
end
raise "define: #{sum}" unless sum == $iters / 2 + ($iters - $iters / 2) * 2

# Removing a method
parent = Class.new { def m; 2; end }
child = Class.new(parent) { def m; 1; end }
obj = child.new
sum = 0
i = 0
while i < $iters
  child.remove_method(:m) if i == $iters / 2
  sum += obj.m
  i += 1
end
raise "remove: #{sum}" unless sum == $iters / 2 + ($iters - $iters / 2) * 2

puts 'OK'
