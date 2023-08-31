;+
; :Description:
;    Create an empty IDL graphics window.
;
; :Params:
;
; :Keywords:
;    _REF_EXTRA
;
; :Returns:
;    Object Reference
;-
function window, DEBUG=debug, $
  EVENT_HANDLER=eventHandler, $
  MOUSE_DOWN_HANDLER=MouseDownHandler, $
  MOUSE_UP_HANDLER=MouseUpHandler, $
  MOUSE_MOTION_HANDLER=MouseMotionHandler, $
  MOUSE_WHEEL_HANDLER=MouseWheelHandler, $
  KEYBOARD_HANDLER=KeyboardHandler, $
  SELECTION_CHANGE_HANDLER=SelectionChangeHandler, $
  NAME=name, UVALUE=uvalue, $   ; handle manually so they don't get lost
  _REF_EXTRA=ex

  compile_opt idl2, hidden
@graphic_error

  Graphic, _EXTRA=ex, GRAPHIC=graphic

  if (ISA(eventHandler) || ISA(MouseDownHandler) || ISA(MouseUpHandler) || $
    ISA(MouseMotionHandler) || ISA(MouseWheelHandler) || $
    ISA(KeyboardHandler) || ISA(SelectionChangeHandler) || $
    ISA(name) || ISA(uvalue)) then begin
    ; For NAME, be sure to also set the WINDOW_TITLE so that
    ; the "tool name" matches the Window name.
    graphic.SetProperty, $
      EVENT_HANDLER=eventHandler, $
      MOUSE_DOWN_HANDLER=MouseDownHandler, $
      MOUSE_UP_HANDLER=MouseUpHandler, $
      MOUSE_MOTION_HANDLER=MouseMotionHandler, $
      MOUSE_WHEEL_HANDLER=MouseWheelHandler, $
      KEYBOARD_HANDLER=KeyboardHandler, $
      SELECTION_CHANGE_HANDLER=SelectionChangeHandler, $
      NAME=name, UVALUE=uvalue, WINDOW_TITLE=name
  endif

  return, graphic
end
