import numpy as np
import open3d as o3d

def getVolume(data):

    separatedCategory = [[], [], [], [], [], [], [], [], [], [], [], [], []]
    
    for point in data:
        separatedCategory[int(point[6])].append(point)
        
    data = []
    objIndentifier = 0
    
    for category in separatedCategory:
        if not category:
            continue

        category = np.array(category)
        pcd = o3d.geometry.PointCloud()
        pcd.points = o3d.utility.Vector3dVector(category[:, 0:3])
        
        labels = pcd.cluster_dbscan(eps=0.05, min_points=15)
        points = []
        
        for i in range(category.shape[0]):
            if labels[i] != -1:
                arr = np.append(category[i], [labels[i]])
                points.append(arr)

        points = np.array(points)
        if (points.shape[0] == 0):
            continue

        points = points[points[:, 7].argsort()]
        
        splitCategory = np.split(points[:,0:7], np.unique(points[:, 7], return_index=True)[1][1:])
        
        for obj in splitCategory:
            if obj.shape[0] < 4:
                continue
            
            try:
                pcdVolume = o3d.geometry.PointCloud()
                pcdVolume.points = o3d.utility.Vector3dVector(obj[:, 0:3])
                hull, _ = pcdVolume.compute_convex_hull()
                hull.orient_triangles()
                
                volume = hull.get_volume()
            except:
                volume = -1
            
            for i in range(obj.shape[0]):
                arr = np.append(obj[i], [volume, objIndentifier])
                data.append(arr.tolist())
            
            objIndentifier += 1
                
    return data

def getVolumeCBL(data, inference):
    return getVolume(getDataLabel(data, inference))

def getDataLabel(data_point, data_label):
    data_point = np.array(data_point)
    data_label = np.array(data_label).astype(np.int32)
    new_data = np.zeros((data_label.shape[0], 7))
    new_data[:, 0:6] = data_point[data_label[:, 0], 0:6]
    new_data[:, 6] = data_label[:, 1]
    return new_data.tolist()
