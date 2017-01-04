import processing.video.*;
import java.util.ArrayList;
import java.util.List;

int CHORD_NUM = 3;
String[] chordsArray = {"laMineur", "sol", "miMineur"};
java.lang.reflect.Method method;
int chordIndex = 0;

Capture video;
color red = color(255, 0, 0); //index
color green = color(0, 255, 0); //middle
color blue = color(0, 0, 255); //ring


color yellow = color(255, 255, 0); //detected
color purple = color(0, 0, 0); //marker

PointKMean[] pointsPrevious = new PointKMean[4];


void setup() {
  size(640, 480);   
  video = new Capture(this, 640, 480, 30);
  video.start();
}

void captureEvent(Capture video) {
  video.read();
}


//detect if the point is dominantly green
boolean totalColor(color px)
{
  return green(px) >95 && red(px)+blue(px) <170;
}

void draw() {

  if (keyPressed) {
    if (key == 'p' )
    {
      chordIndex = (chordIndex + 1) % CHORD_NUM;
      System.out.println(chordIndex);
    }
  } 


  background(0);
  pushMatrix();

  scale(-1, 1);

  video.loadPixels();
  // Create an opaque image of the same size as the original
  PImage luminanceDetector = createImage(video.width, video.height, RGB);
  List points = new ArrayList<PointKMean>();
  for (int y = 2; y < video.height -2; y++) {
    for (int x = 2; x < video.width -2; x++) { //we don't take the border
      color px = video.get(x, y);
      color px_up = video.get(x, y-1);
      color px_down = video.get(x, y+1);
      color px_left = video.get(x-1, y);
      color px_right = video.get(x+1, y);    
      color px_up2 = video.get(x, y-2);
      color px_down2 = video.get(x, y+2);
      color px_left2 = video.get(x-2, y);
      color px_right2 = video.get(x+2, y);

      //detect an area of 9 green pixels, to erase false positive
      if (totalColor(px) &&  totalColor(px_up) && totalColor(px_down) 
        && totalColor(px_left) && totalColor(px_right)&&  totalColor(px_up2) && totalColor(px_down2) 
        && totalColor(px_left2) && totalColor(px_right2) )
      {
        luminanceDetector.pixels[y * video.width + x] = yellow; //color every detected pixels in red
        PointKMean p = new PointKMean(x, y);
        if (points.size() == 0)
        {
          p.setCluster(1);
          points.add(p); //add the point to the list of detected points if the list is empty
        } else
        {

          //add the point to the list if the list is not empty, and there is no close pixel already added
          boolean close = false;
          for (int i = 0; i< points.size(); i++)
          { 
            if (PointKMean.distance(p, (PointKMean)points.get(i)) < 30 ) //set arbitrarily a minimum distance between 2 clusters
            {
              close = true;
              ((PointKMean)points.get(i)).setCluster(((PointKMean)points.get(i)).getCluster()+1);
            }
          }
          if (!close)
          {
            points.add(p);
            p.setCluster(1);
          }
        }
      } else {
        luminanceDetector.pixels[y * video.width + x] = px;
      }
    }
  }

  //erase very small clusters
  for (int i = 0; i < points.size(); i++)
  {
    if (((PointKMean)points.get(i)).getCluster() <3) 
    {
      points.remove(i);
    }
  }

  if (points.size() == 4) //if only our markers are detected
  {  
    PointKMean[] sortedPoints =  sortPoints(points); //sort the list of clusters
    sortedPoints = checkStability(sortedPoints); //Stabilize de detection
    PointKMean p1 = sortedPoints[0];
    PointKMean p2 = sortedPoints[1];
    PointKMean p3 = sortedPoints[2];
    PointKMean p4 = sortedPoints[3];



    colorAround(p1, luminanceDetector, purple);
    colorAround(p2, luminanceDetector, purple);
    colorAround(p3, luminanceDetector, purple);
    colorAround(p4, luminanceDetector, purple);

    //find the perspective matrix
    float [][] matrix = {
      {p2.getX() - p1.getX(), p3.getX() - p1.getX(), p1.getX()}, 
      {p2.getY() - p1.getY(), p3.getY() - p1.getY(), p1.getY()}, 
      {0, 0, 1}
    };

    //draw chord      
    switch(chordIndex)
    {
    case 1:
      miMineur(matrix, luminanceDetector);
      break;
    case 2:
      laMineur(matrix, luminanceDetector);
      break;
    default:
      sol(matrix, luminanceDetector);
      break;
    }
  }
  luminanceDetector.updatePixels();

  image(luminanceDetector, -width, 0, width, height); // Draw the new image     
  popMatrix();
}

PointKMean[] sortPoints( List points)
{

  PointKMean[] pointsSorted = new PointKMean[4];
  //variables before being sorted
  PointKMean _p1 = (PointKMean)points.get(0);
  PointKMean _p2 = (PointKMean)points.get(1);
  PointKMean _p3 = (PointKMean)points.get(2);
  PointKMean _p4 = (PointKMean)points.get(3);

  //find the 2 smallest Y among the 4 points
  PointKMean min1Y = _p1;
  int index =0;
  for (int j=0; j< points.size(); j++)
  {
    if (((PointKMean)points.get(j)).getY()< min1Y.getY())
    {
      min1Y = (PointKMean)points.get(j);
      index = j;
    }
  }
  points.remove(index);
  PointKMean min2Y = (PointKMean)points.get(0);
  index =0;
  for (int j=0; j< points.size(); j++)
  {
    if (((PointKMean)points.get(j)).getY()< min2Y.getY())
    {
      min2Y = (PointKMean)points.get(j);
      index = j;
    }
  }
  points.remove(index);


  //find the smallest X amongs the smallest Y
  if (min1Y.getX() <= min2Y.getX())
  {
    pointsSorted[3] = min1Y;
    pointsSorted[2] = min2Y;
  } else
  {
    pointsSorted[3] = min2Y;
    pointsSorted[2] = min1Y;
  }
  //find the smallest X among the biggest Y
  min1Y = (PointKMean)points.get(0);
  min2Y = (PointKMean)points.get(1);
  if (min1Y.getX() <= min2Y.getX())
  {
    pointsSorted[1] = min1Y;
    pointsSorted[0] = min2Y;
  } else
  {
    pointsSorted[1] = min2Y;
    pointsSorted[0] = min1Y;
  }

  return pointsSorted;
}

void colorAround(PointKMean p, PImage luminanceDetector, color couleur)
{
  luminanceDetector.pixels[(p.getY()-1) * width + p.getX()] = couleur;
  luminanceDetector.pixels[(p.getY()+1) * width + p.getX()] = couleur;
  luminanceDetector.pixels[p.getY() * width + (p.getX()-1)] = couleur;
  luminanceDetector.pixels[p.getY() * width + (p.getX()+1)] = couleur;

  luminanceDetector.pixels[(p.getY()-2) * width + p.getX()] =couleur;
  luminanceDetector.pixels[(p.getY()+2) * width + p.getX()] = couleur;
  luminanceDetector.pixels[p.getY() * width + (p.getX()-2)] = couleur;
  luminanceDetector.pixels[p.getY() * width + (p.getX()+2)] = couleur;

  luminanceDetector.pixels[(p.getY()-1) * width + p.getX()-1] =couleur;
  luminanceDetector.pixels[(p.getY()+1) * width + p.getX()+1] = couleur;
  luminanceDetector.pixels[(p.getY()+1) * width + p.getX()-1] =couleur;
  luminanceDetector.pixels[(p.getY()-1) * width + p.getX()+1] = couleur;
}

void bigColorAround(PointKMean p, PImage luminanceDetector, color couleur)
{
  colorAround( p, luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX()+1, p.getY()), luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX()-1, p.getY()), luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX(), p.getY()+1), luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX(), p.getY()-1), luminanceDetector, couleur);

  colorAround( new PointKMean(p.getX()+2, p.getY()), luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX()-2, p.getY()), luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX(), p.getY()+2), luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX(), p.getY()-2), luminanceDetector, couleur);

  colorAround( new PointKMean(p.getX()+1, p.getY()+1), luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX()-1, p.getY()-1), luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX()-1, p.getY()+1), luminanceDetector, couleur);
  colorAround( new PointKMean(p.getX()+1, p.getY()-1), luminanceDetector, couleur);
}


void display(String s, PointKMean p)
{
  System.out.println(s + " X: " + p.getX() + " Y: "+p.getY());
}

void laMineur(float[][] matrix, PImage luminanceDetector)
{
  PointKMean index = calculPoint(2.0f, 0.5f, matrix);
  bigColorAround(index, luminanceDetector, red);

  PointKMean middle = calculPoint(5.0f, 1.7f, matrix);
  bigColorAround(middle, luminanceDetector, green);

  PointKMean ring = calculPoint(6.5f, 1.0f, matrix);
  bigColorAround(ring, luminanceDetector, blue);
}

void sol(float[][] matrix, PImage luminanceDetector)
{
  PointKMean index = calculPoint(6.0f, 2.5f, matrix);
  bigColorAround(index, luminanceDetector, red);

  PointKMean middle = calculPoint(9.0f, 3.3f, matrix);
  bigColorAround(middle, luminanceDetector, green);

  PointKMean ring = calculPoint(9.0f, -0.6f, matrix);
  bigColorAround(ring, luminanceDetector, blue);
}

void miMineur(float[][] matrix, PImage luminanceDetector)
{
  PointKMean middle = calculPoint(5.5f, 2.3f, matrix);
  bigColorAround(middle, luminanceDetector, red);

  PointKMean ring = calculPoint(7.0f, 1.5f, matrix);
  bigColorAround(ring, luminanceDetector, green);
}

//bring the coordinate in the guitar frame between 0 and 1
float convertX(float value)
{
  return (float)(value/14.5f);
}

float convertY(float value)
{
  return (float)(value/3.0f);
}


//pointX and pointY are the coordinate of the position in the guitar frame
PointKMean calculPoint(float pointX, float pointY, float[][] matrix)
{

  float[] point = {convertX(pointX), convertY(pointY), 1};
  float xAfter = (matrix[0][0] * point[0] + matrix[0][1] * point[1] +matrix[0][2]);
  float yAfter = (matrix[1][0] * point[0] + matrix[1][1] * point[1] +matrix[1][2]);
  float zAfter = (matrix[2][0] * point[0] + matrix[2][1] * point[1] +matrix[2][2]);

  PointKMean finger = new PointKMean((int)(xAfter/zAfter), (int)(yAfter/zAfter));
  return finger;
}

PointKMean[] checkStability(List points)
{

  if (pointsPrevious.size() !=0)
  {
    if (distance((PointKMean)points[0], (PointKMean)pointsPrevious[0]) < 3)
    {
      points[0] = (PointKMean)pointsPrevious[0];
    }
    if (distance((PointKMean)points[1], (PointKMean)pointsPrevious[1]) < 3)
    {
      points[1] = (PointKMean)pointsPrevious[1];
    }
    if (distance((PointKMean)points[2], (PointKMean)pointsPrevious[2]) < 3)
    {
      points[2] = (PointKMean)pointsPrevious[2];
    }
    if (distance((PointKMean)points[3], (PointKMean)pointsPrevious[3]) < 3)
    {
      points[3] = (PointKMean)pointsPrevious[3];
    }
  }
  pointsPrevious = points;
  return points;
}