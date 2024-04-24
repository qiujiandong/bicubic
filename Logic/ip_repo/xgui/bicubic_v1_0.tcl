# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "IRQ_CYCLES" -parent ${Page_0}


}

proc update_PARAM_VALUE.FRACTION_BITS { PARAM_VALUE.FRACTION_BITS } {
	# Procedure called to update FRACTION_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRACTION_BITS { PARAM_VALUE.FRACTION_BITS } {
	# Procedure called to validate FRACTION_BITS
	return true
}

proc update_PARAM_VALUE.IRQ_CYCLES { PARAM_VALUE.IRQ_CYCLES } {
	# Procedure called to update IRQ_CYCLES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IRQ_CYCLES { PARAM_VALUE.IRQ_CYCLES } {
	# Procedure called to validate IRQ_CYCLES
	return true
}


proc update_MODELPARAM_VALUE.IRQ_CYCLES { MODELPARAM_VALUE.IRQ_CYCLES PARAM_VALUE.IRQ_CYCLES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IRQ_CYCLES}] ${MODELPARAM_VALUE.IRQ_CYCLES}
}

proc update_MODELPARAM_VALUE.FRACTION_BITS { MODELPARAM_VALUE.FRACTION_BITS PARAM_VALUE.FRACTION_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRACTION_BITS}] ${MODELPARAM_VALUE.FRACTION_BITS}
}

