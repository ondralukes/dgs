<template>
  <div>
    <TransactionOverlay v-if="txn!==null" :txn="txn" @done="onDone"/>
    <h1>{{name}}</h1>
    <div v-if="finalized">finalized</div>
    <h2>Add member</h2>
    <form class="member-form" @submit="addMember">
      <PersonSelector @select="selectedMemberId=$event" :storage-id="storageId"/>
      <br>
      <input type="submit" value="Add">
    </form>
    <h2>Add Grade</h2>
    <form @submit="addGrade">
      <input ref="gradeName" type="text" placeholder="Name">
      <br>
      <div v-for="m in members" :key="m[0]">
        <label>
          {{m[1]}}
          <input :ref="`grade-${m[0]}`" type="number" min="0" max="255">
        </label>
        <br>
      </div>
      <br>
      <input type="submit" value="Add">
    </form>
    <button @click="finalize" type="button">Finalize</button>
  </div>
</template>

<script>
import TransactionOverlay from "@/components/TransactionOverlay";
import PersonSelector from "@/components/PersonSelector";

export default {
  name: "ClassAdmin",
  components: {PersonSelector, TransactionOverlay},
  data(){
    return{
      name: '',
      finalized: false,
      id: null,
      storageId: null,
      members: [],
      txn: null,
      selectedMemberId: null
    }
  },
  async created() {
    this.id = parseInt(this.$route.params.id);
    this.updateMembers();
    const info = await this.$globalState.getClassInfo(this.id);
    this.name = info.name;
    this.finalized = info.finalized;
    this.storageId = info.storageId;
  },
  methods: {
    onDone(){
      this.txn = null;
      this.updateMembers();
    },
    addMember(e){
      e.preventDefault();
      if(this.selectedMemberId === null) return;
      this.txn = this.$globalState.addClassMember(this.id, this.selectedMemberId);
    },
    addGrade(e){
      e.preventDefault();
      const values = [];
      for(const [id, ] of this.members){
        values.push([
          id,
          parseInt(this.$refs[`grade-${id}`][0].value)
        ]);
      }
      this.txn = this.$globalState.addGrade(this.id, this.$refs.gradeName.value, values);
    },
    finalize(){
      this.txn = this.$globalState.finalizeClass(this.id);
    },
    async updateMembers(){
      this.members = await this.$globalState.getClassMembers(this.id);
    }
  }
}
</script>

<style scoped>
.member-form{
  width: 250px;
  margin: auto;
}
.member-form > *{
  width: 100%;
}
</style>
