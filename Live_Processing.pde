import processing.video.*;
import java.util.ArrayList;
import java.util.List;


Capture video;

//Number of Clusters. This metric should be related to the number of points
    private int NUM_CLUSTERS = 4;    
    //Number of Points
    private int NUM_POINTS = 15;
    //Min and Max X and Y
    private static final int MAX_COORDINATE_X = 640;
    private static final int MAX_COORDINATE_Y = 480;
    
    private List points = new ArrayList();
    private List clusters = new ArrayList();
      
    
void setup() {
   size(640,480);
   
   //printArray(Capture.list());
   
   video = new Capture(this, 640, 480, 30);
   video.start();
}

void captureEvent(Capture video) {
   video.read(); 
}

void draw() {
   background(0);
   pushMatrix();
   
     scale(-1,1);
     //image(video, -width, 0);
     //image(webcam.get(),-width,0);
   
     video.loadPixels();
      // Create an opaque image of the same size as the original
      PImage luminanceDetector = createImage(video.width, video.height, RGB);
      for (int y = 0; y < video.height; y++) { // Skip top and bottom edges
        for (int x = 0; x < video.width; x++) { // Skip left and right edges
          color px = video.get(x,y);
          if(red(px) + green(px) + blue(px) > 764.8 )
          {
             luminanceDetector.pixels[y * video.width + x] = color(255,0,0);
          }       
          else {
              luminanceDetector.pixels[y * video.width + x] = px;
          }
        }
      }
      init(luminanceDetector);
      calculate(luminanceDetector);
      
      for(int i=0; i< points.size();i++)
      {
        PointKMean p = (PointKMean)points.get(i);
        luminanceDetector.pixels[(int)p.getY() * video.width + (int)p.getX()] = color(0,255,0);
      }
      luminanceDetector.updatePixels();
      image(luminanceDetector, -width, 0,width, height); // Draw the new image     
      
    popMatrix();
}

public List createRandomPoints(int max_x, int max_y, int number, PImage luminanceDetector) {
      List points = new ArrayList(number);
      for(int i = 0; i < number; i++) {
        PointKMean p = PointKMean.createRandomPoint(max_x,max_y);
        while(luminanceDetector.pixels[(int)p.getY() * video.width + (int)p.getX()] != color(255,0,0))
        {
          p = PointKMean.createRandomPoint(max_x,max_y);
        }
        points.add(p);
      }
      return points;
    }
    
  //Initializes the process
    public void init( PImage luminanceDetector) {
      //Create Points
      points = createRandomPoints(MAX_COORDINATE_X,MAX_COORDINATE_Y,NUM_POINTS,luminanceDetector);
      
      //Create Clusters
      //Set Random Centroids
      for (int i = 0; i < NUM_CLUSTERS; i++) {
        Cluster cluster = new Cluster(i);
        PointKMean centroid = PointKMean.createRandomPoint(MAX_COORDINATE_X,MAX_COORDINATE_Y);
        cluster.setCentroid(centroid);
        clusters.add(cluster);
      }
      
      //Print Initial state
      plotClusters();
    }

  private void plotClusters() {
      for (int i = 0; i < NUM_CLUSTERS; i++) {
        Cluster c = (Cluster)clusters.get(i);
        c.plotCluster();
      }
    }
    
  //The process to calculate the K Means, with iterating method.
    public void calculate( PImage luminanceDetector) {
        boolean finish = false;
        int iteration = 0;
        
        // Add in new data, one at a time, recalculating centroids with each new one. 
        while(!finish) {
          //Clear cluster state
          clearClusters();
          
          List lastCentroids = getCentroids();
          
          //Assign points to the closer cluster
          assignCluster();
            
            //Calculate new centroids.
          calculateCentroids();
          
          iteration++;
          
          List currentCentroids = getCentroids();
          
          //Calculates total distance between new and old Centroids
          double distance = 0;
          for(int i = 0; i < lastCentroids.size(); i++) {
            distance += PointKMean.distance((PointKMean)lastCentroids.get(i),(PointKMean)currentCentroids.get(i));
          }
          System.out.println("#################");
          System.out.println("Iteration: " + iteration);
          System.out.println("Centroid distances: " + distance);
          plotClusters();
                    
          if(distance == 0) {
            finish = true;
          }
        }
    }
    
    private void clearClusters() {
      for(int i = 0 ; i < clusters.size(); i++) {
        Cluster c = (Cluster)clusters.get(i);
        c.clear();
      }
    }
    
    private List getCentroids() {
      List centroids = new ArrayList(NUM_CLUSTERS);
       for(int i = 0 ; i < clusters.size(); i++) {
        Cluster c = (Cluster)clusters.get(i);
        PointKMean aux = c.getCentroid();
        PointKMean point = new PointKMean(aux.getX(),aux.getY());
        centroids.add(point);
      }
      return centroids;
    }
    
    private void assignCluster() {
        double max = Double.MAX_VALUE;
        double min = max; 
        int cluster = 0;                 
        double distance = 0.0; 
        
       for(int j = 0 ; j < points.size(); j++) {
        PointKMean p = (PointKMean)points.get(j);
          min = max;
            for(int i = 0; i < NUM_CLUSTERS; i++) {
              Cluster c = (Cluster)clusters.get(i);
                distance = PointKMean.distance(p, c.getCentroid());
                if(distance < min){
                    min = distance;
                    cluster = i;
                }
            }
            p.setCluster(cluster);
            
             Cluster clusterFinal = (Cluster)clusters.get(cluster);
            clusterFinal.addPoint(p);
        }
    }
    
    private void calculateCentroids() {
       for(int i = 0 ; i < clusters.size(); i++) {
        Cluster c = (Cluster)clusters.get(i);
            double sumX = 0;
            double sumY = 0;
            List list = c.getPoints();
            int n_points = list.size();
            
            for(int j = 0 ; j < points.size(); j++) {
        PointKMean p = (PointKMean)points.get(j);
              sumX += p.getX();
                sumY += p.getY();
            }
            
            PointKMean centroid = c.getCentroid();
            if(n_points > 0) {
              double newX = sumX / n_points;
              double newY = sumY / n_points;
                centroid.setX(newX);
                centroid.setY(newY);
            }
        }
    }