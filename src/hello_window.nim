import glm
import nimgl/glfw
import nimgl/opengl
import utils/gl


var bgColor = vec3(51f, 190f, 255f).toRGB
var isRed = false


proc keyProc(window: GLFWWindow, key: int32, scancode: int32, action: int32,
    mods: int32): void {.cdecl.} =
  if key == GLFWKey.Escape and action == GLFWPress:
    window.setWindowShouldClose(true)
  elif key == GLFWKey.Space and action == GLFWPress:
    defer: isRed = not isRed
    bgColor =
      if not isRed:
        vec3(235f, 64f, 52f).toRGB
      else:
        vec3(51f, 190f, 255f).toRGB


var vbo: uint32

var vert = @[
  -0.5f, -0.5f, 0.0f,
   0.5f, -0.5f, 0.0f,
   0.0f,  0.5f, 0.0f
]

proc main* =
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_FALSE)

  let w: GLFWWindow = glfwCreateWindow(800, 600, "NimGL")
  if w == nil:
    quit(-1)

  discard w.setKeyCallback(keyProc)
  w.makeContextCurrent()

  doAssert glInit()

  glGenBuffers(1, vbo.addr);
  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBufferData(GL_ARRAY_BUFFER, cint(cfloat.sizeof * vert.len), vert[0].addr, GL_STATIC_DRAW)

  while not w.windowShouldClose:
    glfwPollEvents()
    glClearColor(bgColor.x, bgColor.y, bgColor.z, 1f)
    glClear(GL_COLOR_BUFFER_BIT)
    w.swapBuffers()

  w.destroyWindow()
  glfwTerminate()
