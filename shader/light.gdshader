shader_type canvas_item;
render_mode light_only;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
}

void light() {

    vec4 c = LIGHT_COLOR * LIGHT_ENERGY;
    c.rgb = clamp(c.rgb, 0.0, 1.0);
    LIGHT = c;
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
}
