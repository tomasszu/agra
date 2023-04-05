<h1> Description of the graphics library "agra" </h1>
<h3> Course project supervised by Dr. sc. comp Leo Seļāvo at the University of Latvia.</h3>
<p> (Latviski apraksts pieejams repozitorijā esošajā failā apraksts.pdf) </p>
<br>
<p>
This is a graphics library capable of "drawing" figures such as point, line, circle and triangle on a 2D plane. These figures are written to a buffer (ideally implemented as a 2D matrix), which are later printed on the screen or other output.
</p>

<h3>Functionality implemented in the library (written in C and Assembly):</h3>

<ol>
  <li><b>Color installation.</b> The color is set using a defined struct and sent to the assembler file, where the color is used to fill in the pixels in the buffer until replaced.</li>
  <li><b>Pixel drawing.</b> Gets its x and y coordinates and places it in the buffer. Takes into account the color and draw operation. Drawing operations are able to modify the output of the buffer using the logical operations mentioned in the requirements. In my implementation, this function also checks if it is not drawn for the first time, because the buffer must be cleared before the first drawing (for which a separate function is created).</li>
  <li><b>Drawing a line.</b> Gets the coordinates of the start and end points. The line itself is drawn using an advanced Bresenham line drawing algorithm. For this most widely available algorithm I had to look for improvements, because at a certain slope of the line (greater slope of y than slope of x) an incorrect line was drawn that did not go to the end point.</li>
  <li><b>Drawing a circle.</b> Also used is Bresenham's "Midpoint circle algorithm", which physically marks the circle using a sub-function that after each calculation marks 8 pixels of the surrounding configuration. The function receives the center point (x,y) and radius of the circle.</li>
  <li><b>Filling a triangle.</b> This, the longest algorithm, fills the contours of the triangle by drawing horizontal lines in several steps (configurations) until the entire area is filled. A sub-function SWAP is often used, which swaps two variables (eg x1 and x2) for places. The coordinates of the three vertices are received as parameters.</li>
  <li><b>Returning the address of the buffer</b> so that it can be accessed in the assembler. <b>Returning the width and length of the buffer</b> to be able to control the walking around the buffer and <b>printing a Frame</b> that prints the buffer to the screen.</li>
</ol>
