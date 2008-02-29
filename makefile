examples = org.eclipse.swt.examples/src
controlexample = org/eclipse/swt/examples/controlexample
graphics = org/eclipse/swt/examples/graphics
paint = org/eclipse/swt/examples/paint

.PHONY: build
build: example graphics paint

.PHONY: example
example:
	make -f app.mk \
		name=example \
		properties-file=$(examples)/examples_control.properties \
		data-files="$(wildcard $(examples)/$(controlexample)/*.png) \
			$(wildcard $(examples)/$(controlexample)/*.gif) \
			$(wildcard $(examples)/$(controlexample)/*.bmp) \
			$(wildcard $(examples)/$(controlexample)/*.html)" \
		data-directory=$(controlexample) \
		sources="$(shell find $(examples)/$(controlexample) -name '*.java')" \
		source-directory=$(examples) \
		main-class=org.eclipse.swt.examples.controlexample.ControlExample

.PHONY: graphics
graphics:
	make -f app.mk \
		name=graphics \
		properties-file=$(examples)/examples_graphics.properties \
		data-files="$(wildcard $(examples)/$(graphics)/*.png) \
			$(wildcard $(examples)/$(graphics)/*.gif) \
			$(wildcard $(examples)/$(graphics)/*.jpg) \
			$(wildcard $(examples)/$(graphics)/*.bmp)" \
		data-directory=$(graphics) \
		sources="$(shell find $(examples)/$(graphics) -name '*.java')" \
		source-directory=$(examples) \
		main-class=org.eclipse.swt.examples.graphics.GraphicsExample

.PHONY: paint
paint:
	make -f app.mk \
		name=paint \
		properties-file=$(examples)/examples_paint.properties \
		data-files="$(wildcard $(examples)/$(paint)/*.gif)" \
		data-directory=$(paint) \
		sources="$(shell find $(examples)/$(paint) -name '*.java')" \
		source-directory=$(examples) \
		main-class=org.eclipse.swt.examples.paint.PaintExample

.PHONY: clean
clean:
	rm -rf build
