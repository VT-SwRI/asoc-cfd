new_project \
    -name {led_test} \
    -location {C:\Users\zackp\OneDrive\Documents\ECE_4806\Libero\ethernet_module\designer\impl1\led_test_fp} \
    -mode {single}
set_programming_file -file {C:\Users\zackp\OneDrive\Documents\ECE_4806\Libero\ethernet_module\designer\impl1\led_test.pdb}
set_programming_action -action {PROGRAM}
run_selected_actions
save_project
close_project
