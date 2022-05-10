import numpy as np
import open3d as o3d
import h5py

pcd = o3d.io.read_point_cloud("office_1.txt", 'xyzrgb')
hull, _ = pcd.compute_convex_hull()
hull.orient_triangles()
print(hull.get_volume())
o3d.visualization.draw_geometries([pcd])