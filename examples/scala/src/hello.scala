object Hello {
  // This var triggers DisableSyntax.noVars rule
  var mutableState = 0

  // This null triggers DisableSyntax.noNulls rule
  val nullValue: String = null

  def main(args: Array[String]): Unit = {
    println("Hello, world!")
  }
}
