import nimgl/glfw
import nimgl/opengl
import glm
import os


template shaderPath(path: string): string = "../shaders/" & path & ".glsl"


proc keyProc(window: GLFWWindow, key: int32, scancode: int32, action: int32, mods: int32): void {.cdecl.} =
  if key == GLFWKey.Escape and action == GLFWPress:
    window.setWindowShouldClose(true)
  if key == GLFWKey.Space:
    glPolygonMode(GL_FRONT_AND_BACK, if action != GLFWRelease: GL_LINE else: GL_FILL)


proc statusShader(shader: uint32) =
  var status: int32
  glGetShaderiv(shader, GL_COMPILE_STATUS, status.addr);
  if status != GL_TRUE.ord:
    var
      log_length: int32
      message = newSeq[char](1024)
    glGetShaderInfoLog(shader, 1024, log_length.addr, message[0].addr);
    echo message


proc toRGB(vec: Vec3[float32]): Vec3[float32] =
  vec3(vec.x / 255, vec.y / 255, vec.z / 255)


template glClearColorRGB(rgb: Vec3[float32], alpha: float32) =
  glClearColor(rgb.r, rgb.b, rgb.b, alpha)


proc main =
  if os.getEnv("CI") != "":
    quit()

  # GLFW
  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_FALSE)

  let w: GLFWWindow = glfwCreateWindow(800, 600, "NimGL", nil, nil)
  doAssert w != nil

  discard w.setKeyCallback(keyProc)
  w.makeContextCurrent

  # Opengl
  doAssert glInit()

  echo $glVersionMajor & "." & $glVersionMinor

  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  # Hello square!
  var mesh: tuple[vbo, vao, ebo: uint32]

  var vertices = @[
     0.3f,  0.3f,
     0.3f, -0.3f,
    -0.3f, -0.3f,
    -0.3f,  0.3f
  ]

  var indices = @[
    0'u32, 1'u32, 3'u32,
    1'u32, 2'u32, 3'u32
  ]

  glGenBuffers(1, mesh.vbo.addr)
  glGenBuffers(1, mesh.ebo.addr)
  glGenVertexArrays(1, mesh.vao.addr)

  glBindVertexArray(mesh.vao)

  glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ebo)

  glBufferData(GL_ARRAY_BUFFER, cint(cfloat.sizeof * vertices.len), vertices[0].addr, GL_STATIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, cint(cuint.sizeof * indices.len), indices[0].addr, GL_STATIC_DRAW)

  glEnableVertexAttribArray(0)
  glVertexAttribPointer(0'u32, 2, EGL_FLOAT, false, cfloat.sizeof * 2, nil)

  var vertex: uint32 = glCreateShader(GL_VERTEX_SHADER)
  var vsrc: cstring = static staticRead(shaderPath"vertex_shader")
  glShaderSource(vertex, 1'i32, vsrc.addr, nil)
  glCompileShader(vertex)
  statusShader(vertex)

  var fragment: uint32 = glCreateShader(GL_FRAGMENT_SHADER)
  var fsrc: cstring = static staticRead(shaderPath"fragment_shader")
  glShaderSource(fragment, 1, fsrc.addr, nil)
  glCompileShader(fragment)
  statusShader(fragment)

  var program: uint32 = glCreateProgram()
  glAttachShader(program, vertex)
  glAttachShader(program, fragment)
  glLinkProgram(program)

  var log_length: int32
  var message = newSeq[char](1024)
  var pLinked: int32

  glGetProgramiv(program, GL_LINK_STATUS, pLinked.addr);
  if pLinked != GL_TRUE.ord:
    glGetProgramInfoLog(program, 1024, log_length.addr, message[0].addr);
    echo message

  let uColor = glGetUniformLocation(program, "uColor")
  let uMVP = glGetUniformLocation(program, "uMVP")
  var clearColor = vec3(33f, 33f, 33f).toRgb()
  var color = vec3(50f, 205f, 50f).toRgb()
  var mvp = ortho(-2f, 2f, -1.5f, 1.5f, -1f, 1f)

  # app loop
  while not w.windowShouldClose:
    # clear background
    glClearColorRGB(clearColor, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    glUseProgram(program)
    glUniform3fv(uColor, 1, color.caddr)
    glUniformMatrix4fv(uMVP, 1, false, mvp.caddr)

    glBindVertexArray(mesh.vao)
    glDrawElements(GL_TRIANGLES, indices.len.cint, GL_UNSIGNED_INT, nil)

    w.swapBuffers
    glfwPollEvents()
  
  w.destroyWindow
  glfwTerminate()

  glDeleteVertexArrays(1, mesh.vao.addr)
  glDeleteBuffers(1, mesh.vbo.addr)
  glDeleteBuffers(1, mesh.ebo.addr)


main()
