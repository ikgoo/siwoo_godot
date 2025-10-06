using UnityEngine;

public class MeshPhysics : MonoBehaviour
{
    void Start()
    {
        ApplyPhysicsToAllMeshes();
    }

    void ApplyPhysicsToAllMeshes()
    {
        // InteriorStairs, Basement 등 모든 부모 오브젝트들을 찾아서 처리
        Transform[] allObjects = FindObjectsOfType<Transform>();
        
        foreach (Transform obj in allObjects)
        {
            // MeshFilter가 없어도 물리 적용
            // MeshCollider 추가
            if (!obj.TryGetComponent<MeshCollider>(out MeshCollider meshCollider))
            {
                meshCollider = obj.gameObject.AddComponent<MeshCollider>();
                meshCollider.convex = true;
            }
            
            // Rigidbody 추가
            if (!obj.TryGetComponent<Rigidbody>(out Rigidbody rb))
            {
                rb = obj.gameObject.AddComponent<Rigidbody>();
                rb.mass = 1.0f;
                rb.useGravity = true;
                rb.isKinematic = false;
            }
        }
    }
} 