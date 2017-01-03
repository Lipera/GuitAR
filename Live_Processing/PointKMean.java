import java.util.ArrayList;
import java.util.List;
import java.util.Random;
 import processing.video.*;
 
public class PointKMean {
 
    private int x = 0;
    private int y = 0;
    private int cluster_number = 0;
 
    public PointKMean(int x, int y)
    {
        this.setX(x);
        this.setY(y);
    }
    
    public void setX(int x) {
        this.x = x;
    }
    
    public int getX()  {
        return this.x;
    }
    
    public void setY(int y) {
        this.y = y;
    }
    
    public int getY() {
        return this.y;
    }
    
    public void setCluster(int n) {
        this.cluster_number = n;
    }
    
    public int getCluster() {
        return this.cluster_number;
    }
    
    //Calculates the distance between two points.
    protected static double distance(PointKMean p, PointKMean centroid) {
        return Math.sqrt(Math.pow((centroid.getY() - p.getY()), 2) + Math.pow((centroid.getX() - p.getX()), 2));
    }
    
    //Creates random point
    protected static PointKMean createRandomPoint(int max_x, int max_y) {
      Random r = new Random();
      int x = max_x * r.nextInt();
      int y = max_y * r.nextInt();
      return new PointKMean(x,y);
    }
    
    
    
    public String toString() {
      return "("+x+","+y+")";
    }
}