# System Architecture Diagrams

## 1. Overall System Architecture

```mermaid
graph TB
    subgraph "User Layer"
        SA["📱 Student App<br/>(Flutter)"]
        DA["🚗 Driver App<br/>(Flutter)"]
        AD["💻 Admin Dashboard<br/>(Flutter Web)"]
    end

    subgraph "Service Layer"
        LS["Location Service"]
        PCS["Pickup Coordination<br/>Service"]
        ROS["Route Optimization<br/>Service"]
        AS["Analytics Service"]
    end

    subgraph "DSA Layer"
        GM["Graph Model"]
        DA2["Dijkstra Algorithm"]
        PQ["Priority Queue"]
        RQ["Request Queue"]
        HM["HashMap"]
        GT["Graph Traversal"]
    end

    subgraph "Backend - Firebase"
        FB["Firebase Authentication"]
        FS["Firestore Database"]
        RDB["Realtime Database"]
        FCM["Cloud Messaging"]
        CS["Cloud Storage"]
    end

    subgraph "External Services"
        GMAPI["Google Maps API"]
        LOC["Location Services"]
        GEO["Geolocation API"]
    end

    SA --> LS
    SA --> PCS
    SA --> ROS
    
    DA --> LS
    DA --> PCS
    DA --> ROS
    
    AD --> AS
    AD --> PCS
    AD --> ROS

    LS --> RDB
    PCS --> FS
    PCS --> RQ
    PCS --> PQ
    ROS --> GM
    ROS --> DA2
    ROS --> GT
    
    PCS --> HM
    LS --> HM

    FS --> FB
    RDB --> FCM
    CS --> FB

    GMAPI --> SA
    GMAPI --> DA
    GMAPI --> AD
    LOC --> LS
    GEO --> LS
```

---

## 2. Data Flow - Pickup Request

```mermaid
sequenceDiagram
    participant Student as 👤 Student
    participant SA as Student App
    participant PCS as Pickup Service
    participant PS as Priority Scheduler
    participant Firebase as Firebase
    participant DA as Driver App
    participant Driver as 👨‍✈️ Driver

    Student->>SA: Request Pickup
    SA->>SA: Get current location
    SA->>PCS: createPickupRequest()
    PCS->>Firebase: Save request
    PCS->>PS: addPickupRequest()
    Firebase->>DA: Notification (New Pickup)
    DA->>PS: getNextPickup()
    PS-->>DA: Highest Priority Request
    DA->>Driver: Show Request (Distance, ETA)
    Driver->>DA: Accept Request
    DA->>PCS: assignBusToPickup()
    PCS->>Firebase: Update request status
    Firebase->>SA: Notification (Bus Assigned, ETA)
    SA->>SA: Start sharing location
    Driver->>DA: Mark: Student Boarded
    DA->>PCS: completePickupRequest()
    PCS->>Firebase: Stop location sharing
    SA->>SA: Stop location sharing
```

---

## 3. Route Optimization Flow

```mermaid
graph LR
    A["Current Bus<br/>Position"] -->|GPS| B["Get Pending<br/>Pickups"]
    B --> C["Priority Queue<br/>Sorting"]
    C --> D["Calculate Distance<br/>to Each"]
    D --> E["Dijkstra<br/>Algorithm"]
    E --> F["Generate Pickup<br/>Sequence"]
    F --> G["Calculate<br/>ETAs"]
    G --> H["Update Driver<br/>Map"]
    
    style E fill:#FF6B9D
    style C fill:#FFC93C
    style H fill:#00D9FF
```

---

## 4. Algorithm Architecture

```mermaid
graph TB
    subgraph "Graph Structure"
        BN["Bus Network<br/>Graph"]
        BS["Bus Stops"]
        RD["Road Edges"]
        BN --> BS
        BN --> RD
    end

    subgraph "Shortest Path"
        DA["Dijkstra<br/>Algorithm"]
        PQ2["Priority Queue"]
        DA --> PQ2
    end

    subgraph "Pickup Optimization"
        PQ["Pickup Priority<br/>Queue"]
        PS["Priority Score<br/>Calculator"]
        PQ --> PS
    end

    subgraph "Request Processing"
        RQ["Request Queue<br/>FIFO"]
    end

    subgraph "Data Lookups"
        HM["Entity HashMap<br/>O(1) Lookups"]
    end

    subgraph "Graph Analysis"
        BFS["BFS Traversal"]
        DFS["DFS Traversal"]
        CC["Connected<br/>Components"]
        BFS --> CC
        DFS --> CC
    end

    BS --> DA
    PS --> PQ2
    PQ2 --> HM
```

---

## 5. Priority Queue Scoring

```mermaid
graph TD
    A["Pickup Request"] --> B["Calculate Priority Score"]
    
    B --> C["Base Priority Level"]
    B --> D["Wait Time Factor"]
    B --> E["Distance Factor"]
    B --> F["Desired Time Factor"]
    
    C -->|Critical: 1000| X["Priority Score"]
    C -->|High: 700| X
    C -->|Medium: 400| X
    C -->|Low: 100| X
    
    D -->|+1 per minute| X
    E -->|Closer = Higher<br/>max 5km radius| X
    F -->|Time-sensitive<br/>+50 per min until deadline| X
    
    X --> G["Sorted Queue<br/>Highest First"]
    
    style X fill:#4ECDC4
    style G fill:#44A08D
```

---

## 6. Firebase Collections Schema

```mermaid
graph TB
    subgraph "Users & Identity"
        U["users/{userId}"]
        S["students/{studentId}"]
        D["drivers/{driverId}"]
    end

    subgraph "Transportation"
        B["buses/{busId}"]
        R["routes/{routeId}"]
        BS["bus_stops/{stopId}"]
    end

    subgraph "Operations"
        PR["pickup_requests/{requestId}"]
        T["trips/{tripId}"]
        LL["live_locations/{entityId}"]
    end

    subgraph "Analytics"
        A["analytics/{eventId}"]
        RN["road_network/{edgeId}"]
    end

    U --> S
    U --> D
    B --> D
    PR --> S
    PR --> B
    T --> B
    T --> D
    LL --> B
    LL --> S
    A --> PR
```

---

## 7. Realtime Database Structure

```mermaid
graph TD
    RDB["Realtime Database"]
    
    RDB --> BL["buses_live_locations/"]
    RDB --> SL["student_live_locations/"]
    RDB --> PR2["pickup_requests_active/"]
    RDB --> DS["drivers_status/"]
    
    BL --> B1["bus_001/<br/>lat, lng, ts"]
    BL --> B2["bus_002/<br/>lat, lng, ts"]
    
    SL --> ST1["std_001/<br/>lat, lng, ts"]
    
    PR2 --> PRX["req_001/<br/>status, ETA"]
    
    DS --> D1["drv_001/<br/>status, location"]
```

---

## 8. Student App Screens Flow

```mermaid
graph TD
    A["Login/Signup"] --> B["Home Screen<br/>Bottom Nav"]
    
    B --> C["Track Buses<br/>Google Maps"]
    B --> D["Request Pickup<br/>Location + Submit"]
    B --> E["Trip History<br/>Past Pickups"]
    B --> F["Profile<br/>Edit Info"]
    
    D --> G["Wait for<br/>Assignment"]
    G --> H["Bus Assigned<br/>ETA Display"]
    H --> I["Share Location<br/>During Pickup"]
    I --> J["Boarded/<br/>Completed"]
    
    J --> E
    
    style D fill:#FF6B6B
    style H fill:#4ECDC4
    style I fill:#FFE66D
    style J fill:#95E1D3
```

---

## 9. DSA Time Complexity

```mermaid
graph LR
    A["Operation"] --> B["Time Complexity"]
    
    B --> C["Graph Operations"]
    B --> D["Dijkstra"]
    B --> E["Priority Queue"]
    B --> F["HashMap"]
    B --> G["BFS/DFS"]
    
    C --> C1["Add: O(1)<br/>Neighbors: O(d)"]
    D --> D1["O(V+E)logV"]
    E --> E1["Insert: O(logn)<br/>Delete: O(logn)<br/>Peek: O(1)"]
    F --> F1["Insert: O(1)<br/>Lookup: O(1)<br/>Delete: O(1)"]
    G --> G1["O(V+E)"]
    
    style D1 fill:#FF6B9D
    style E1 fill:#FFC93C
    style F1 fill:#00D9FF
```

---

## 10. System Components Interaction

```mermaid
graph TB
    SA["Student App"]
    DA["Driver App"]
    AA["Admin App"]
    
    SA -->|Request Pickup| LS["Location<br/>Service"]
    SA -->|Track Bus| LS
    
    DA -->|Share GPS| LS
    DA -->|Get Pickup| PCS["Pickup<br/>Coordination"]
    
    AA -->|Monitor| ROS["Route<br/>Optimization"]
    
    LS -->|Update Location| RDB["Realtime<br/>Database"]
    PCS -->|Manage Requests| FS["Firestore"]
    ROS -->|Calculate Routes| DSA["DSA<br/>Algorithms"]
    
    RDB -->|Stream Update| SA
    RDB -->|Stream Update| DA
    FS -->|Sync Data| AA
```

---

**Last Updated**: January 2024
